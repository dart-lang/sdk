// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
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
  final LibraryFragmentImpl _unitElement;

  var _exportDirectiveIndex = 0;
  var _importDirectiveIndex = 0;
  var _partDirectiveIndex = 0;

  _EnclosingContext _enclosingContext;
  int _nextUnnamedId = 0;

  ElementBuilder({
    required LibraryBuilder libraryBuilder,
    required LibraryFragmentImpl unitElement,
  }) : _libraryBuilder = libraryBuilder,
       _unitElement = unitElement,
       _enclosingContext = _EnclosingContext(
         instanceElementBuilder: null,
         fragment: unitElement,
       );

  Linker get _linker => _libraryBuilder.linker;

  void buildDeclarationElements(CompilationUnit unit) {
    _visitPropertyFirst<TopLevelVariableDeclaration>(unit.declarations);
    _unitElement.classes = _enclosingContext.classes;
    _unitElement.enums = _enclosingContext.enums;
    _unitElement.extensions = _enclosingContext.extensions;
    _unitElement.extensionTypes = _enclosingContext.extensionTypes;
    _unitElement.functions = _enclosingContext.functions;
    _unitElement.getters = _enclosingContext.getters;
    _unitElement.mixins = _enclosingContext.mixins;
    _unitElement.setters = _enclosingContext.setters;
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
      libraryDirective.element2 = libraryElement;
      libraryElement.documentationComment = getCommentNodeRawText(
        libraryDirective.documentationComment,
      );
      libraryElement.metadata = _buildMetadata(libraryDirective.metadata);
      return;
    }

    // Otherwise use the first directive.
    var firstDirective = unit.directives.firstOrNull;
    if (firstDirective != null) {
      libraryElement.documentationComment = getCommentNodeRawText(
        firstDirective.documentationComment,
      );
      MetadataImpl? firstDirectiveMetadata;
      switch (firstDirective) {
        case ExportDirectiveImpl():
          firstDirectiveMetadata = firstDirective.libraryExport?.metadata;
        case ImportDirectiveImpl():
          firstDirectiveMetadata = firstDirective.libraryImport?.metadata;
        case PartDirectiveImpl():
          firstDirectiveMetadata = firstDirective.partInclude?.metadata;
        case LibraryDirectiveImpl():
          // Impossible, since there is no library directive.
          break;
        case PartOfDirectiveImpl():
          // Can only occur in erroneous code (this is the defining
          // compilation unit)
          break;
      }
      if (firstDirectiveMetadata != null) {
        libraryElement.metadata = firstDirectiveMetadata;
      }
    }
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var fragmentName = _getFragmentName(nameToken);
    var fragment = ClassFragmentImpl(
      name2: fragmentName,
      nameOffset: nameToken.offset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAbstract = node.abstractKeyword != null;
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.isBase = node.baseKeyword != null;
    fragment.isFinal = node.finalKeyword != null;
    fragment.isInterface = node.interfaceKeyword != null;
    fragment.isMixinClass = node.mixinKeyword != null;
    if (node.sealedKeyword != null) {
      fragment.isAbstract = true;
      fragment.isSealed = true;
    }
    fragment.hasExtendsClause = node.extendsClause != null;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    var refName = fragment.name2 ?? '${_nextUnnamedId++}';
    var fragmentReference = _enclosingContext.addClass(refName, fragment);
    if (!fragment.isAugmentation && fragmentName != null) {
      _libraryBuilder.declare(fragmentName, fragmentReference);
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
    fragment.fields = holder.fields;
    fragment.getters = holder.getters;
    fragment.setters = holder.setters;
    fragment.methods = holder.methods;
    fragment.constructors = holder.constructors;

    node.extendsClause?.accept(this);
    node.withClause?.accept(this);
    node.implementsClause?.accept(this);

    elementBuilder.addFragment(fragment);
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var fragmentName = _getFragmentName(nameToken);

    var fragment = ClassFragmentImpl(
      name2: fragmentName,
      nameOffset: nameToken.offset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAbstract = node.abstractKeyword != null;
    fragment.isBase = node.baseKeyword != null;
    fragment.isFinal = node.finalKeyword != null;
    fragment.isInterface = node.interfaceKeyword != null;
    fragment.isMixinApplication = true;
    fragment.isMixinClass = node.mixinKeyword != null;
    if (node.sealedKeyword != null) {
      fragment.isAbstract = true;
      fragment.isSealed = true;
    }
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    var refName = fragment.name2 ?? '${_nextUnnamedId++}';
    var reference = _enclosingContext.addClass(refName, fragment);
    if (!fragment.isAugmentation && fragmentName != null) {
      _libraryBuilder.declare(fragmentName, reference);
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
  void visitConstructorDeclaration(covariant ConstructorDeclarationImpl node) {
    var nameNode = node.name ?? node.returnType;
    var name = node.name?.lexeme ?? '';
    if (name == 'new') {
      // A constructor declared as `C.new` is unnamed, and is modeled as such.
      name = '';
    }
    var nameOffset = nameNode.offset;

    String fragmentName;
    int? fragmentNameOffset;
    if ((node.period, node.name) case (var _?, var name?)) {
      fragmentName = _getFragmentName(name) ?? 'new';
      fragmentNameOffset = _getFragmentNameOffset(name);
    } else {
      fragmentName = 'new';
    }

    var fragment = ConstructorFragmentImpl(
      name2: fragmentName,
      nameOffset: nameOffset,
    );
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.isConst = node.constKeyword != null;
    fragment.isExternal = node.externalKeyword != null;
    fragment.isFactory = node.factoryKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);
    fragment.typeName = node.returnType.name;
    fragment.typeNameOffset = node.returnType.offset;
    fragment.periodOffset = node.period?.offset;
    fragment.nameEnd = nameNode.end;
    fragment.nameOffset2 = fragmentNameOffset;
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    if (fragment.isConst || fragment.isFactory) {
      fragment.constantInitializers = node.initializers;
    }

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    var reference = _enclosingContext.addConstructor(fragment);

    var containerBuilder = _enclosingContext.instanceElementBuilder!;
    var containerElement = containerBuilder.element;
    var containerRef = containerElement.reference!.getChild('@constructor');
    var elementReference = containerRef.addChild(fragment.name2);

    ConstructorElementImpl2(
      name3: fragment.name2,
      reference: elementReference,
      firstFragment: fragment,
    );

    _buildExecutableElementChildren(
      reference: reference,
      fragment: fragment,
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
    var fragmentName = _getFragmentName(nameToken);

    var fragment = EnumFragmentImpl(
      name2: fragmentName,
      nameOffset: nameOffset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    var refName = fragment.name2 ?? '${_nextUnnamedId++}';
    var reference = _enclosingContext.addEnum(refName, fragment);
    if (!fragment.isAugmentation && fragmentName != null) {
      _libraryBuilder.declare(fragmentName, reference);
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
      var field =
          ConstFieldFragmentImpl(
              name2: _getFragmentName(nameToken),
              nameOffset: constant.name.offset,
            )
            ..hasImplicitType = true
            ..hasInitializer = true
            ..isAugmentation = constant.augmentKeyword != null
            ..isConst = true
            ..isEnumConstant = true
            ..isStatic = true;
      field.nameOffset2 = _getFragmentNameOffset(nameToken);
      _setCodeRange(field, constant);
      _setDocumentation(field, constant);
      field.metadata = _buildMetadata(constant.metadata);

      var constantArguments = constant.arguments;
      var constructorSelector = constantArguments?.constructorSelector;
      var constructorName = constructorSelector?.name.name;

      var initializer = InstanceCreationExpressionImpl(
        keyword: null,
        constructorName: ConstructorNameImpl(
          type: NamedTypeImpl(
            importPrefix: null,
            name: StringToken(TokenType.STRING, fragment.name2 ?? '', -1),
            typeArguments: constantArguments?.typeArguments,
            question: null,
          ),
          period: constructorName != null ? Tokens.period() : null,
          name:
              constructorName != null
                  ? SimpleIdentifierImpl(
                    token: StringToken(TokenType.STRING, constructorName, -1),
                  )
                  : null,
        ),
        argumentList:
            constantArguments != null
                ? constantArguments.argumentList
                : ArgumentListImpl(
                  leftParenthesis: Tokens.openParenthesis(),
                  arguments: [],
                  rightParenthesis: Tokens.closeParenthesis(),
                ),
        typeArguments: null,
      );

      var variableDeclaration = VariableDeclarationImpl(
        comment: null,
        metadata: [],
        name: StringToken(TokenType.STRING, name, -1),
        equals: Tokens.eq(),
        initializer: initializer,
      );
      constant.declaredFragment = field;
      variableDeclaration.declaredFragment = field;
      VariableDeclarationListImpl(
        comment: null,
        metadata: null,
        lateKeyword: null,
        keyword: null,
        type: null,
        variables: [variableDeclaration],
      );
      _linker.elementNodes[field] = variableDeclaration;

      AstNodeImpl.linkNodeTokens(initializer);
      field.constantInitializer = initializer;

      var refName = field.name2 ?? '${_nextUnnamedId++}';
      holder.addNonSyntheticField(refName, field);

      valuesElements.add(
        SimpleIdentifierImpl(token: StringToken(TokenType.STRING, name, -1)),
      );
      valuesNames.add(name);

      FieldElementImpl2(
        reference: elementBuilder.element.reference
            .getChild('@field')
            .addChild(refName),
        firstFragment: field,
      );
    }

    // Build the 'values' field.
    var valuesField =
        ConstFieldFragmentImpl(name2: 'values', nameOffset: -1)
          ..hasEnclosingTypeParameterReference = false
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
    AstNodeImpl.linkNodeTokens(initializer);
    valuesField.constantInitializer = initializer;

    var variableDeclaration = VariableDeclarationImpl(
      comment: null,
      metadata: [],
      name: StringToken(TokenType.STRING, 'values', -1),
      equals: Tokens.eq(),
      initializer: initializer,
    );
    var valuesTypeNode = NamedTypeImpl(
      importPrefix: null,
      name: StringToken(TokenType.STRING, 'List', -1),
      typeArguments: TypeArgumentListImpl(
        leftBracket: Tokens.lt(),
        arguments: [
          NamedTypeImpl(
            importPrefix: null,
            name: StringToken(TokenType.STRING, fragment.name2 ?? '', -1),
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

    FieldElementImpl2(
      reference: elementBuilder.element.reference
          .getChild('@field')
          .addChild('values'),
      firstFragment: valuesField,
    );

    _libraryBuilder.implicitEnumNodes[fragment] = ImplicitEnumNodes(
      element: fragment,
      valuesTypeNode: valuesTypeNode,
      valuesNode: variableDeclaration,
      valuesElement: valuesField,
      valuesNames: valuesNames,
      valuesInitializer: initializer,
    );

    node.withClause?.accept(this);
    node.implementsClause?.accept(this);

    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      _visitPropertyFirst<FieldDeclaration>(node.members);
    });

    fragment.typeParameters = holder.typeParameters;
    fragment.fields = holder.fields;
    fragment.getters = holder.getters;
    fragment.setters = holder.setters;
    fragment.methods = holder.methods;
    fragment.constructors = holder.constructors;
    elementBuilder.addFragment(fragment);
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    var index = _exportDirectiveIndex++;
    var exportElement = _unitElement.libraryExports[index];
    exportElement.metadata = _buildMetadata(node.metadata);
    node.libraryExport = exportElement;
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
    var fragmentName = _getFragmentName(nameToken);

    var fragment = ExtensionFragmentImpl(
      name2: fragmentName,
      nameOffset: nameOffset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    var refName = fragment.name2 ?? '${_nextUnnamedId++}';
    var reference = _enclosingContext.addExtension(refName, fragment);

    if (name != null) {
      if (!fragment.isAugmentation && fragmentName != null) {
        _libraryBuilder.declare(fragmentName, reference);
      }
    }

    FragmentedElementBuilder? elementBuilder;
    if (name != null) {
      elementBuilder = _libraryBuilder.elementBuilderGetters[name];
      elementBuilder?.setPreviousFor(fragment);
      if (fragment.isAugmentation &&
          elementBuilder is ExtensionElementBuilder) {
      } else {
        var elementReference = _libraryBuilder.reference
            .getChild('@extension')
            .addChild(refName);
        var element = ExtensionElementImpl2(elementReference, fragment);
        _libraryBuilder.element.extensions.add(element);

        elementBuilder = ExtensionElementBuilder(
          firstFragment: fragment,
          element: element,
        );
        _libraryBuilder.elementBuilderGetters[name] = elementBuilder;
      }
    } else {
      var elementReference = _libraryBuilder.reference
          .getChild('@extension')
          .addChild(refName);
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
    fragment.fields = holder.fields;
    fragment.getters = holder.getters;
    fragment.setters = holder.setters;
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
    var fragmentName = _getFragmentName(nameToken);

    var fragment = ExtensionTypeFragmentImpl(
      name2: fragmentName,
      nameOffset: nameToken.offset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    var refName = fragment.name2 ?? '${_nextUnnamedId++}';
    var reference = _enclosingContext.addExtensionType(refName, fragment);
    if (!fragment.isAugmentation && fragmentName != null) {
      _libraryBuilder.declare(fragmentName, reference);
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
        extensionFragment: fragment,
      );
      _visitPropertyFirst<FieldDeclaration>(node.members);
    });

    fragment.typeParameters = holder.typeParameters;
    fragment.fields = holder.fields;
    fragment.getters = holder.getters;
    fragment.setters = holder.setters;
    fragment.methods = holder.methods;
    fragment.constructors = holder.constructors;

    var executables = const <ExecutableFragmentImpl>[]
        .followedBy(fragment.accessors)
        .followedBy(fragment.methods);
    for (var executable in executables) {
      executable.isExtensionTypeMember = true;
    }

    node.implementsClause?.accept(this);
    elementBuilder.addFragment(fragment);
  }

  @override
  void visitFieldDeclaration(covariant FieldDeclarationImpl node) {
    var metadata = _buildMetadata(node.metadata);
    for (var variable in node.fields.variables) {
      var nameToken = variable.name;
      var nameOffset = nameToken.offset;

      var fragment = FieldFragmentImpl(
        name2: _getFragmentName(nameToken),
        nameOffset: nameOffset,
      );
      if (variable.initializer case var initializer?) {
        if (node.fields.isConst) {
          fragment = ConstFieldFragmentImpl(
            name2: _getFragmentName(nameToken),
            nameOffset: nameOffset,
          )..constantInitializer = initializer;
        } else if (_enclosingContext.constFieldsForFinalInstance) {
          if (node.fields.isFinal && !node.isStatic) {
            var constElement = ConstFieldFragmentImpl(
              name2: _getFragmentName(nameToken),
              nameOffset: nameOffset,
            )..constantInitializer = initializer;
            fragment = constElement;
            _libraryBuilder.finalInstanceFields.add(constElement);
          }
        }
      }

      fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      fragment.hasInitializer = variable.initializer != null;
      fragment.isAbstract = node.abstractKeyword != null;
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isConst = node.fields.isConst;
      fragment.isCovariant = node.covariantKeyword != null;
      fragment.isExternal = node.externalKeyword != null;
      fragment.isFinal = node.fields.isFinal;
      fragment.isLate = node.fields.isLate;
      fragment.isStatic = node.isStatic;
      fragment.metadata = metadata;
      _setCodeRange(fragment, variable);
      _setDocumentation(fragment, node);

      if (node.fields.type == null) {
        fragment.hasImplicitType = true;
      }

      var refName = fragment.name2 ?? '${_nextUnnamedId++}';
      _enclosingContext.addNonSyntheticField(refName, fragment);

      _linker.elementNodes[fragment] = variable;
      variable.declaredFragment = fragment;

      var containerBuilder = _enclosingContext.instanceElementBuilder!;
      var containerElement = containerBuilder.element;
      var containerRef = containerElement.reference!.getChild('@field');
      var elementReference = containerRef.addChild(refName);

      FieldElementImpl2(reference: elementReference, firstFragment: fragment);
    }
    _buildType(node.fields.type);
  }

  @override
  void visitFieldFormalParameter(covariant FieldFormalParameterImpl node) {
    var nameToken = node.name;
    var name2 = _getFragmentName(nameToken);
    var nameOffset2 = nameToken.offset.nullIfNegative;

    FormalParameterFragmentImpl fragment;
    var parent = node.parent;
    if (parent is DefaultFormalParameterImpl) {
      fragment = DefaultFieldFormalParameterElementImpl(
        nameOffset: nameOffset2 ?? -1,
        name2: name2,
        nameOffset2: nameOffset2,
        parameterKind: node.kind,
      )..constantInitializer = parent.defaultValue;
      _linker.elementNodes[fragment] = parent;
      var refName = node.isNamed ? name2 : null;
      _enclosingContext.addParameter(refName, fragment);
    } else {
      fragment = FieldFormalParameterFragmentImpl(
        nameOffset: nameOffset2 ?? -1,
        name2: name2,
        nameOffset2: nameOffset2,
        parameterKind: node.kind,
      );
      _linker.elementNodes[fragment] = node;
      _enclosingContext.addParameter(null, fragment);
    }

    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.hasImplicitType = node.type == null && node.parameters == null;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);

    node.declaredFragment = fragment;

    // TODO(scheglov): check that we don't set reference for parameters
    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      if (formalParameters != null) {
        formalParameters.accept(this);
        fragment.parameters = holder.parameters;
      }

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
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
    var name2 = _getFragmentName(nameToken);

    var functionExpression = node.functionExpression;
    var body = functionExpression.body;

    Reference reference;
    ExecutableFragmentImpl executableFragment;
    FragmentedElementBuilder? elementBuilder;
    if (node.isGetter) {
      var getterFragment = GetterFragmentImpl(
        name2: name2,
        nameOffset: nameOffset,
      );
      getterFragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      getterFragment.isAugmentation = node.augmentKeyword != null;
      getterFragment.isStatic = true;

      var refName = getterFragment.name2 ?? '${_nextUnnamedId++}';
      reference = _enclosingContext.addGetter(refName, getterFragment);
      executableFragment = getterFragment;

      if (!getterFragment.isAugmentation) {
        var variableFragment =
            _buildSyntheticVariable(name: name, accessorElement: getterFragment)
                as TopLevelVariableFragmentImpl;

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
      var setterFragment = SetterFragmentImpl(
        name2: name2,
        nameOffset: nameOffset,
      );
      setterFragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      setterFragment.isAugmentation = node.augmentKeyword != null;
      setterFragment.isStatic = true;

      var refName = setterFragment.name2 ?? '${_nextUnnamedId++}';
      reference = _enclosingContext.addSetter(refName, setterFragment);
      executableFragment = setterFragment;

      if (!setterFragment.isAugmentation) {
        var variableFragment =
            _buildSyntheticVariable(name: name, accessorElement: setterFragment)
                as TopLevelVariableFragmentImpl;

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
      var fragment = TopLevelFunctionFragmentImpl(
        name2: name2,
        nameOffset: nameOffset,
      );
      fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isStatic = true;
      executableFragment = fragment;

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
        var element = TopLevelFunctionElementImpl(elementReference, fragment);
        _libraryBuilder.element.topLevelFunctions.add(element);

        elementBuilder = TopLevelFunctionElementBuilder(
          element: element,
          firstFragment: fragment,
        );
        _libraryBuilder.elementBuilderGetters[name] = elementBuilder;
      }
    }

    executableFragment.hasImplicitReturnType = node.returnType == null;
    executableFragment.isAsynchronous = body.isAsynchronous;
    executableFragment.isExternal = node.externalKeyword != null;
    executableFragment.isGenerator = body.isGenerator;
    executableFragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(executableFragment, node);
    _setDocumentation(executableFragment, node);

    node.declaredFragment = executableFragment;
    _linker.elementNodes[executableFragment] = node;

    _buildExecutableElementChildren(
      reference: reference,
      fragment: executableFragment,
      formalParameters: functionExpression.parameters,
      typeParameters: functionExpression.typeParameters,
    );

    if (!executableFragment.isAugmentation && name2 != null) {
      var getterOrSetterName = node.isSetter ? '$name2=' : name2;
      _libraryBuilder.declare(getterOrSetterName, reference);
    }

    _buildType(node.returnType);
  }

  @override
  void visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var name2 = _getFragmentName(nameToken);

    var fragment = TypeAliasFragmentImpl(
      name2: name2,
      nameOffset: nameToken.offset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isFunctionTypeAliasBased = true;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    var refName = fragment.name2 ?? '${_nextUnnamedId++}';
    var reference = _enclosingContext.addTypeAlias(refName, fragment);
    if (name2 != null) {
      _libraryBuilder.declare(name2, reference);
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
      node.returnType?.accept(this);
      node.parameters.accept(this);
    });

    var aliasedElement = GenericFunctionTypeFragmentImpl.forOffset(
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
    var name2 = _getFragmentName(nameToken);
    var nameOffset2 = nameToken.offset.nullIfNegative;

    FormalParameterFragmentImpl fragment;
    var parent = node.parent;
    if (parent is DefaultFormalParameterImpl) {
      fragment = DefaultParameterFragmentImpl(
        nameOffset: nameOffset2 ?? -1,
        name2: name2,
        nameOffset2: nameOffset2,
        parameterKind: node.kind,
      )..constantInitializer = parent.defaultValue;
      _linker.elementNodes[fragment] = parent;
    } else {
      fragment = FormalParameterFragmentImpl(
        nameOffset: nameOffset2 ?? -1,
        name2: name2,
        nameOffset2: nameOffset2,
        parameterKind: node.kind,
      );
      _linker.elementNodes[fragment] = node;
    }
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isExplicitlyCovariant = node.covariantKeyword != null;
    fragment.isFinal = node.isFinal;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;
    var refName = node.isNamed ? name2 : null;
    _enclosingContext.addParameter(refName, fragment);

    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      formalParameters.accept(this);
      fragment.parameters = holder.parameters;

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
      }
    });

    _buildType(node.returnType);
  }

  @override
  void visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    var fragment = GenericFunctionTypeFragmentImpl.forOffset(node.offset);
    _unitElement.encloseElement(fragment);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      formalParameters.accept(this);
      fragment.parameters = holder.parameters;

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
      }
    });

    _buildType(node.returnType);
  }

  @override
  void visitGenericTypeAlias(covariant GenericTypeAliasImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var name2 = _getFragmentName(nameToken);

    var fragment = TypeAliasFragmentImpl(
      name2: name2,
      nameOffset: nameToken.offset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    var refName = fragment.name2 ?? '${_nextUnnamedId++}';
    var reference = _enclosingContext.addTypeAlias(refName, fragment);
    if (!fragment.isAugmentation && name2 != null) {
      _libraryBuilder.declare(name2, reference);
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
      fragment.aliasedElement = typeNode.declaredFragment!;
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
    importElement.metadata = _buildMetadata(node.metadata);
    node.libraryImport = importElement;
  }

  @override
  void visitLibraryDirective(covariant LibraryDirectiveImpl node) {}

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var nameOffset = nameToken.offset;

    Reference reference;
    ExecutableFragmentImpl executableFragment;
    if (node.isGetter) {
      var fragment = GetterFragmentImpl(
        name2: _getFragmentName(nameToken),
        nameOffset: nameOffset,
      );
      fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      fragment.isAbstract = node.isAbstract;
      fragment.isAugmentation = node.augmentKeyword != null;
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
      var fragment = SetterFragmentImpl(
        name2: _getFragmentName(nameToken),
        nameOffset: nameOffset,
      );
      fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      fragment.isAbstract = node.isAbstract;
      fragment.isAugmentation = node.augmentKeyword != null;
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

      var fragment = MethodFragmentImpl(
        name2: _getFragmentName(nameToken),
        nameOffset: nameOffset,
      );
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

      var containerBuilder = _enclosingContext.instanceElementBuilder!;
      var containerElement = containerBuilder.element;
      var containerRef = containerElement.reference!.getChild('@method');
      var elementReference = containerRef.addChild(refName);

      MethodElementImpl2(
        name3: fragment.name2,
        reference: elementReference,
        firstFragment: fragment,
      );
    }
    executableFragment.hasImplicitReturnType = node.returnType == null;
    executableFragment.invokesSuperSelf = node.invokesSuperSelf;
    executableFragment.isAsynchronous = node.body.isAsynchronous;
    executableFragment.isExternal =
        node.externalKeyword != null || node.body is NativeFunctionBody;
    executableFragment.isGenerator = node.body.isGenerator;
    executableFragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(executableFragment, node);
    _setDocumentation(executableFragment, node);

    node.declaredFragment = executableFragment;
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
    var fragmentName = _getFragmentName(nameToken);

    var fragment = MixinFragmentImpl(
      name2: fragmentName,
      nameOffset: nameToken.offset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.isBase = node.baseKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    var refName = fragment.name2 ?? '${_nextUnnamedId++}';
    var reference = _enclosingContext.addMixin(refName, fragment);
    if (!fragment.isAugmentation && fragmentName != null) {
      _libraryBuilder.declare(fragmentName, reference);
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
    fragment.fields = holder.fields;
    fragment.getters = holder.getters;
    fragment.setters = holder.setters;
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
  void visitPartDirective(covariant PartDirectiveImpl node) {
    var index = _partDirectiveIndex++;
    var partElement = _unitElement.parts[index];
    partElement.metadata = _buildMetadata(node.metadata);
    node.partInclude = partElement;
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
  void visitSimpleFormalParameter(covariant SimpleFormalParameterImpl node) {
    var nameToken = node.name;
    var name2 = _getFragmentName(nameToken);
    var nameOffset2 = nameToken?.offset;

    FormalParameterFragmentImpl fragment;
    var parent = node.parent;
    if (parent is DefaultFormalParameterImpl &&
        _enclosingContext.hasDefaultFormalParameters) {
      fragment = DefaultParameterFragmentImpl(
        nameOffset: nameOffset2 ?? -1,
        name2: name2,
        nameOffset2: nameOffset2,
        parameterKind: node.kind,
      )..constantInitializer = parent.defaultValue;
      _linker.elementNodes[fragment] = parent;
      var refName = node.isNamed ? name2 : null;
      _enclosingContext.addParameter(refName, fragment);
    } else {
      fragment = FormalParameterFragmentImpl(
        nameOffset: nameOffset2 ?? -1,
        name2: name2,
        nameOffset2: nameOffset2,
        parameterKind: node.kind,
      );
      _linker.elementNodes[fragment] = node;
      _enclosingContext.addParameter(null, fragment);
    }

    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.hasImplicitType = node.type == null;
    fragment.isExplicitlyCovariant = node.covariantKeyword != null;
    fragment.isFinal = node.isFinal;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);

    node.declaredFragment = fragment;

    _buildType(node.type);
  }

  @override
  void visitSuperFormalParameter(covariant SuperFormalParameterImpl node) {
    var nameToken = node.name;
    var name2 = _getFragmentName(nameToken);
    var nameOffset2 = nameToken.offset.nullIfNegative;

    SuperFormalParameterFragmentImpl fragment;
    var parent = node.parent;
    if (parent is DefaultFormalParameterImpl) {
      fragment = DefaultSuperFormalParameterElementImpl(
        nameOffset: nameOffset2 ?? -1,
        name2: name2,
        nameOffset2: nameOffset2,
        parameterKind: node.kind,
      )..constantInitializer = parent.defaultValue;
      _linker.elementNodes[fragment] = parent;
      var refName = node.isNamed ? name2 : null;
      _enclosingContext.addParameter(refName, fragment);
    } else {
      fragment = SuperFormalParameterFragmentImpl(
        nameOffset: nameOffset2 ?? -1,
        name2: name2,
        nameOffset2: nameOffset2,
        parameterKind: node.kind,
      );
      _linker.elementNodes[fragment] = node;
      _enclosingContext.addParameter(null, fragment);
    }
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.hasImplicitType = node.type == null && node.parameters == null;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);

    node.declaredFragment = fragment;

    // TODO(scheglov): check that we don't set reference for parameters
    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      if (formalParameters != null) {
        formalParameters.accept(this);
        fragment.parameters = holder.parameters;
      }

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
      }
    });

    _buildType(node.type);
  }

  @override
  void visitTopLevelVariableDeclaration(
    covariant TopLevelVariableDeclarationImpl node,
  ) {
    var enclosingRef = _enclosingContext.fragmentReference;

    var metadata = _buildMetadata(node.metadata);
    for (var variable in node.variables.variables) {
      var nameToken = variable.name;
      var name = nameToken.lexeme;
      var nameOffset = nameToken.offset;
      var name2 = _getFragmentName(nameToken);

      TopLevelVariableFragmentImpl fragment;
      if (node.variables.isConst) {
        fragment = ConstTopLevelVariableFragmentImpl(
          name2: name2,
          nameOffset: nameOffset,
        )..constantInitializer = variable.initializer;
      } else {
        fragment = TopLevelVariableFragmentImpl(
          name2: name2,
          nameOffset: nameOffset,
        );
      }

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
          if (name2 != null) {
            _libraryBuilder.declare(name2, ref);
          }

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
          if (name2 != null) {
            _libraryBuilder.declare('$name2=', ref);
          }

          var elementBuilder = SetterElementBuilder(
            element: SetterElementImpl(setter),
            firstFragment: setter,
          );
          _libraryBuilder.elementBuilderSetters[name] = elementBuilder;
        }
      }

      _linker.elementNodes[fragment] = variable;
      variable.declaredFragment = fragment;

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
        var element = TopLevelVariableElementImpl2(elementReference, fragment);
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

    var fragment = TypeParameterFragmentImpl(
      name2: _getFragmentName(nameToken),
      nameOffset: nameToken.offset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;
    _enclosingContext.addTypeParameter(name, fragment);

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

  void _buildExecutableElementChildren({
    required Reference reference,
    required ExecutableFragmentImpl fragment,
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

  MetadataImpl _buildMetadata(List<Annotation> nodeList) {
    var annotations = _buildAnnotationsWithUnit(_unitElement, nodeList);
    return MetadataImpl(annotations);
  }

  /// The [accessorElement] should not be an augmentation.
  PropertyInducingFragmentImpl _buildSyntheticVariable({
    required String name,
    required PropertyAccessorFragmentImpl accessorElement,
  }) {
    var refName = accessorElement.name2 ?? '${_nextUnnamedId++}';
    var enclosingRef = _enclosingContext.fragmentReference;
    var enclosingElement = _enclosingContext.fragment;

    bool canUseExisting(PropertyInducingFragmentImpl property) {
      return property.isSynthetic ||
          accessorElement.isSetter && property.setter == null;
    }

    PropertyInducingFragmentImpl? property;
    if (enclosingElement is LibraryFragmentImpl) {
      // Try to find the variable to attach the accessor.
      var containerRef = enclosingRef.getChild('@topLevelVariable');
      for (var reference in containerRef.getChildrenByName(name)) {
        var existing = reference.element;
        if (existing is TopLevelVariableFragmentImpl &&
            canUseExisting(existing)) {
          property = existing;
          break;
        }
      }

      // If no variable, add a new one.
      // In error cases could be a duplicate.
      if (property == null) {
        var reference = containerRef.addChild(name);
        var variable =
            property = TopLevelVariableFragmentImpl(
              name2: accessorElement.name2,
              nameOffset: -1,
            )..isSynthetic = true;
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
        if (existing is FieldFragmentImpl && canUseExisting(existing)) {
          property = existing;
          break;
        }
      }

      // If no variable, add a new one.
      // In error cases could be a duplicate.
      if (property == null) {
        var reference = containerRef.addChild(name);
        var field =
            property =
                FieldFragmentImpl(name2: accessorElement.name2, nameOffset: -1)
                  ..isStatic = accessorElement.isStatic
                  ..isSynthetic = true;
        _enclosingContext.addFieldSynthetic(reference, field);

        FieldElementImpl2(
          reference: _enclosingContext
              .instanceElementBuilder!
              .element
              .reference!
              .getChild('@field')
              .getChild(name),
          firstFragment: field,
        );
      }
    }

    accessorElement.variable2 = property;
    switch (accessorElement) {
      case GetterFragmentImpl():
        property.getter = accessorElement;
      case SetterFragmentImpl():
        property.setter = accessorElement;
    }
    return property;
  }

  // TODO(scheglov): Maybe inline?
  void _buildType(TypeAnnotation? node) {
    node?.accept(this);
  }

  void _builtRepresentationDeclaration({
    required ExtensionTypeFragmentImpl extensionFragment,
    required ExtensionTypeDeclarationImpl extensionNode,
    required RepresentationDeclarationImpl representation,
  }) {
    var fieldNameToken = representation.fieldName;
    var fieldName = fieldNameToken.lexeme.ifNotEmptyOrElse('<empty>');

    var fieldFragment = FieldFragmentImpl(
      name2: _getFragmentName(fieldNameToken),
      nameOffset: fieldNameToken.offset,
    );
    fieldFragment.nameOffset2 = _getFragmentNameOffset(fieldNameToken);
    fieldFragment.isFinal = true;
    fieldFragment.metadata = _buildMetadata(representation.fieldMetadata);

    var fieldBeginToken =
        representation.fieldMetadata.beginToken ?? representation.fieldType;
    var fieldCodeRangeOffset = fieldBeginToken.offset;
    var fieldCodeRangeLength = fieldNameToken.end - fieldCodeRangeOffset;
    fieldFragment.setCodeRange(fieldCodeRangeOffset, fieldCodeRangeLength);

    representation.fieldFragment = fieldFragment;
    _linker.elementNodes[fieldFragment] = representation;
    _enclosingContext.addNonSyntheticField(fieldName, fieldFragment);

    FieldElementImpl2(
      reference: extensionFragment.element.reference
          .getChild('@field')
          .addChild(fieldName),
      firstFragment: fieldFragment,
    );

    var nameOffset2 = fieldNameToken.offset.nullIfNegative;

    var formalParameterElement =
        FieldFormalParameterFragmentImpl(
            nameOffset: nameOffset2 ?? -1,
            name2: _getFragmentName(fieldNameToken),
            nameOffset2: nameOffset2,
            parameterKind: ParameterKind.REQUIRED,
          )
          ..field = fieldFragment
          ..hasImplicitType = true;
    formalParameterElement.nameOffset2 = _getFragmentNameOffset(fieldNameToken);
    formalParameterElement.setCodeRange(
      fieldCodeRangeOffset,
      fieldCodeRangeLength,
    );

    {
      int? periodOffset;
      int nameOffset;
      int? nameEnd;
      var constructorNameNode = representation.constructorName;
      if (constructorNameNode != null) {
        var nameToken = constructorNameNode.name;
        periodOffset = constructorNameNode.period.offset;
        nameOffset = nameToken.offset;
        nameEnd = nameToken.end;
      } else {
        nameOffset = extensionNode.name.offset;
        nameEnd = extensionNode.name.end;
      }

      String constructorFragmentName;
      int? constructorFragmentOffset;
      if (representation.constructorName case var constructorName?) {
        constructorFragmentName = constructorName.name.lexeme;
        constructorFragmentOffset = constructorName.name.offset;
      } else {
        constructorFragmentName = 'new';
      }

      var constructorFragment =
          ConstructorFragmentImpl(
              name2: constructorFragmentName,
              nameOffset: nameOffset,
            )
            ..isAugmentation = extensionNode.augmentKeyword != null
            ..isConst = extensionNode.constKeyword != null
            ..periodOffset = periodOffset
            ..nameEnd = nameEnd
            ..parameters = [formalParameterElement];
      constructorFragment.typeName = extensionFragment.name2;
      constructorFragment.typeNameOffset = extensionFragment.nameOffset2;
      constructorFragment.nameOffset2 = constructorFragmentOffset;
      _setCodeRange(constructorFragment, representation);

      representation.constructorFragment = constructorFragment;
      _linker.elementNodes[constructorFragment] = representation;
      _enclosingContext.addConstructor(constructorFragment);

      var containerBuilder = _enclosingContext.instanceElementBuilder!;
      var containerElement = containerBuilder.element;
      var containerRef = containerElement.reference!.getChild('@constructor');
      var elementReference = containerRef.addChild(
        extensionFragment.name2 ?? 'new',
      );

      ConstructorElementImpl2(
        name3: constructorFragment.name2,
        reference: elementReference,
        firstFragment: constructorFragment,
      );
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
    LibraryFragmentImpl unitElement,
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

  static void _setCodeRange(FragmentImpl element, AstNode node) {
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

  static void _setDocumentation(FragmentImpl element, AnnotatedNode node) {
    element.documentationComment = getCommentNodeRawText(
      node.documentationComment,
    );
  }
}

class _EnclosingContext {
  final InstanceElementBuilder? instanceElementBuilder;
  final FragmentImpl fragment;
  final List<ClassFragmentImpl> _classes = [];
  final List<ConstructorFragmentImpl> _constructors = [];
  final List<EnumFragmentImpl> _enums = [];
  final List<ExtensionFragmentImpl> _extensions = [];
  final List<ExtensionTypeFragmentImpl> _extensionTypes = [];
  final List<FieldFragmentImpl> _fields = [];
  final List<TopLevelFunctionFragmentImpl> _functions = [];
  final List<MethodFragmentImpl> _methods = [];
  final List<MixinFragmentImpl> _mixins = [];
  final List<FormalParameterFragmentImpl> _parameters = [];
  // TODO(scheglov): Use getters / setters instead.
  final List<PropertyAccessorFragmentImpl> _propertyAccessors = [];
  final List<TopLevelVariableFragmentImpl> _topLevelVariables = [];
  final List<TypeAliasFragmentImpl> _typeAliases = [];
  final List<TypeParameterFragmentImpl> _typeParameters = [];

  /// A class can have `const` constructors, and if it has we need values
  /// of final instance fields.
  final bool constFieldsForFinalInstance;

  /// Not all optional formal parameters can have default values.
  /// For example, formal parameters of methods can, but formal parameters
  /// of function types - not. This flag specifies if we should create
  /// [FormalParameterFragmentImpl]s or [DefaultParameterFragmentImpl]s.
  final bool hasDefaultFormalParameters;

  _EnclosingContext({
    required this.instanceElementBuilder,
    required this.fragment,
    this.constFieldsForFinalInstance = false,
    this.hasDefaultFormalParameters = false,
  });

  List<ClassFragmentImpl> get classes {
    return _classes.toFixedList();
  }

  List<ConstructorFragmentImpl> get constructors {
    return _constructors.toFixedList();
  }

  List<EnumFragmentImpl> get enums {
    return _enums.toFixedList();
  }

  List<ExtensionFragmentImpl> get extensions {
    return _extensions.toFixedList();
  }

  List<ExtensionTypeFragmentImpl> get extensionTypes {
    return _extensionTypes.toFixedList();
  }

  List<FieldFragmentImpl> get fields {
    return _fields.toFixedList();
  }

  Reference get fragmentReference {
    return fragment.reference!;
  }

  List<TopLevelFunctionFragmentImpl> get functions {
    return _functions.toFixedList();
  }

  List<GetterFragmentImpl> get getters {
    return _propertyAccessors.whereType<GetterFragmentImpl>().toFixedList();
  }

  bool get isDartCoreEnum {
    var fragment = this.fragment;
    return fragment is ClassFragmentImpl && fragment.isDartCoreEnum;
  }

  List<MethodFragmentImpl> get methods {
    return _methods.toFixedList();
  }

  List<MixinFragmentImpl> get mixins {
    return _mixins.toFixedList();
  }

  List<FormalParameterFragmentImpl> get parameters {
    return _parameters.toFixedList();
  }

  List<SetterFragmentImpl> get setters {
    return _propertyAccessors.whereType<SetterFragmentImpl>().toFixedList();
  }

  List<TopLevelVariableFragmentImpl> get topLevelVariables {
    return _topLevelVariables.toFixedList();
  }

  List<TypeAliasFragmentImpl> get typeAliases {
    return _typeAliases.toFixedList();
  }

  List<TypeParameterFragmentImpl> get typeParameters {
    return _typeParameters.toFixedList();
  }

  Reference addClass(String name, ClassFragmentImpl element) {
    _classes.add(element);
    var containerName =
        element.isAugmentation ? '@classAugmentation' : '@class';
    return _addReference(containerName, name, element);
  }

  Reference addConstructor(ConstructorFragmentImpl element) {
    _constructors.add(element);

    var containerName =
        element.isAugmentation ? '@constructorAugmentation' : '@constructor';
    var referenceName = element.name2;
    return _addReference(containerName, referenceName, element);
  }

  Reference addEnum(String name, EnumFragmentImpl element) {
    _enums.add(element);
    var containerName = element.isAugmentation ? '@enumAugmentation' : '@enum';
    return _addReference(containerName, name, element);
  }

  Reference addExtension(String name, ExtensionFragmentImpl element) {
    _extensions.add(element);
    var containerName =
        element.isAugmentation ? '@extensionAugmentation' : '@extension';
    return _addReference(containerName, name, element);
  }

  Reference addExtensionType(String name, ExtensionTypeFragmentImpl element) {
    _extensionTypes.add(element);
    var containerName =
        element.isAugmentation
            ? '@extensionTypeAugmentation'
            : '@extensionType';
    return _addReference(containerName, name, element);
  }

  Reference addField(String name, FieldFragmentImpl element) {
    _fields.add(element);
    var containerName =
        element.isAugmentation ? '@fieldAugmentation' : '@field';
    return _addReference(containerName, name, element);
  }

  void addFieldSynthetic(Reference reference, FieldFragmentImpl element) {
    _fields.add(element);
    _bindReference(reference, element);
  }

  Reference addFunction(String name, TopLevelFunctionFragmentImpl element) {
    _functions.add(element);
    var containerName =
        element.isAugmentation ? '@functionAugmentation' : '@function';
    return _addReference(containerName, name, element);
  }

  Reference addGetter(String name, PropertyAccessorFragmentImpl element) {
    _propertyAccessors.add(element);
    var containerName =
        element.isAugmentation ? '@getterAugmentation' : '@getter';
    return _addReference(containerName, name, element);
  }

  Reference addMethod(String name, MethodFragmentImpl element) {
    _methods.add(element);
    var containerName =
        element.isAugmentation ? '@methodAugmentation' : '@method';
    return _addReference(containerName, name, element);
  }

  Reference addMixin(String name, MixinFragmentImpl element) {
    _mixins.add(element);
    var containerName =
        element.isAugmentation ? '@mixinAugmentation' : '@mixin';
    return _addReference(containerName, name, element);
  }

  void addNonSyntheticField(String name, FieldFragmentImpl element) {
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

  Reference? addParameter(String? name, FormalParameterFragmentImpl element) {
    _parameters.add(element);
    if (name == null) {
      return null;
    }
    if (fragment.reference == null) {
      return null;
    }
    return _addReference('@parameter', name, element);
  }

  void addPropertyAccessorSynthetic(PropertyAccessorFragmentImpl element) {
    _propertyAccessors.add(element);
  }

  Reference addSetter(String name, PropertyAccessorFragmentImpl element) {
    _propertyAccessors.add(element);
    var containerName =
        element.isAugmentation ? '@setterAugmentation' : '@setter';
    return _addReference(containerName, name, element);
  }

  Reference addTopLevelVariable(
    String name,
    TopLevelVariableFragmentImpl element,
  ) {
    _topLevelVariables.add(element);
    var containerName =
        element.isAugmentation
            ? '@topLevelVariableAugmentation'
            : '@topLevelVariable';
    return _addReference(containerName, name, element);
  }

  void addTopLevelVariableSynthetic(
    Reference reference,
    TopLevelVariableFragmentImpl element,
  ) {
    _topLevelVariables.add(element);
    _bindReference(reference, element);
  }

  Reference addTypeAlias(String name, TypeAliasFragmentImpl element) {
    _typeAliases.add(element);
    var containerName =
        element.isAugmentation ? '@typeAliasAugmentation' : '@typeAlias';
    return _addReference(containerName, name, element);
  }

  void addTypeParameter(String name, TypeParameterFragmentImpl fragment) {
    _typeParameters.add(fragment);
    this.fragment.encloseElement(fragment);
  }

  Reference _addReference(
    String containerName,
    String name,
    FragmentImpl element,
  ) {
    var containerRef = fragmentReference.getChild(containerName);
    var reference = containerRef.addChild(name);
    _bindReference(reference, element);
    return reference;
  }

  void _bindReference(Reference reference, FragmentImpl fragment) {
    reference.element = fragment;
    fragment.reference = reference;
    this.fragment.encloseElement(fragment);
  }
}
