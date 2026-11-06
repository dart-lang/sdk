// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart' hide ElementKind;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'code_template.dart';

/// The data related to an element that has been replaced by another element.
class ReplacedBy extends Change<_Data> {
  /// The replacing element.
  final ElementDescriptor newElement;

  /// Whether the target also needs to be replaced.
  final bool replaceTarget;

  /// The argument list to be used if replaced by a method with arguments.
  final List<CodeTemplate> arguments = [];

  /// Initialize a newly created transform to describe a replacement of an old
  /// element by a [newElement].
  new({
    required this.newElement,
    required this.replaceTarget,
    List<CodeTemplate>? argumentList,
  }) {
    if (argumentList != null) {
      arguments.addAll(argumentList);
    }
  }

  @override
  // The private type of the [data] parameter is dictated by the signature of
  // the super-method and the class's super-class.
  // ignore: library_private_types_in_public_api
  void apply(DartFileEditBuilder builder, DataDrivenFix fix, _Data data) {
    var referenceRange = data.referenceRange;
    var importElement = _importElement(builder, fix, data);
    builder.addReplacement(referenceRange, (builder) {
      var components = newElement.components;
      if (data.isInstanceMember && !replaceTarget) {
        // Just replace the member on the same type.
        builder.write(components.first);
      } else {
        // Replaces a static access, including any prefix and static scope.
        if (importElement?.prefix case var prefix?) {
          builder
            ..write(prefix)
            ..write('.');
        }
        if (components[0].isEmpty) {
          // An unnamed constructor, always directly inside top-level declaration.
          builder.write(components[1]);
        } else {
          builder.write(components.reversed.join('.'));
        }
      }
      _writeArguments(builder, fix, data);
    });
  }

  @override
  // The private return type is dictated by the signature of the super-method
  // and the class's super-class.
  // ignore: library_private_types_in_public_api
  _Data? validate(DataDrivenFix fix) {
    var node = fix.node;
    // Replaces all targets of static accesses, including prefixes.
    // If [replaceTarget] is `true`, also replace targets of instance
    // accesses.
    if (node is SimpleIdentifier && _isInstanceAccess(node, fix)) {
      return _instanceInvocation(fix, node);
    }
    if (node is NamespaceDirective) {
      if (node.uri case SimpleStringLiteral uri) {
        return _Data(
          range.startOffsetEndOffset(uri.contentsOffset, uri.contentsEnd),
        );
      }
      return null;
    }
    if (node is Comment) {
      return _docImportUri(node, fix);
    }
    var sourceRange = _rangeWithTarget(node, fix);
    return sourceRange == null ? null : _Data(sourceRange);
  }

  bool _canKeepInstanceTarget(DataDrivenFix fix, SimpleIdentifier node) {
    var kind = newElement.kind;
    if (newElement.isStatic ||
        (kind != ElementKind.fieldKind &&
            kind != ElementKind.getterKind &&
            kind != ElementKind.methodKind &&
            kind != ElementKind.setterKind)) {
      return false;
    }
    if (_realTargetOf(node) case ExtensionOverride(:var name)) {
      return newElement.components.length == 2 &&
          name.lexeme == newElement.components[1] &&
          newElement.libraryUris.any(fix.element.libraryUris.contains);
    }
    return true;
  }

  /// Replacement range for the `@docImport` URI selected by [fix] in [node].
  _Data? _docImportUri(Comment node, DataDrivenFix fix) {
    var elements = fix.element.components;
    if (elements.isEmpty) return null;
    var simpleName = elements[0];
    for (var docImport in node.docImports) {
      if (docImport.import.uri case SimpleStringLiteral uri
          when uri.value == simpleName &&
              uri.offset <= fix.selectionOffset &&
              fix.selectionEnd <= uri.end) {
        return _Data(
          range.startOffsetEndOffset(uri.contentsOffset, uri.contentsEnd),
        );
      }
    }
    return null;
  }

  ImportLibraryElementResult? _importElement(
    DartFileEditBuilder builder,
    DataDrivenFix fix,
    _Data data,
  ) {
    var libraryUris = newElement.libraryUris;
    if (libraryUris.isEmpty) {
      return null;
    }
    // A library URI from `libraryUris`, either one already imported,
    // or the first one in the list.
    var libraryUri = _selectImportUri(builder, libraryUris);
    var prefix = replaceTarget
        ? null
        : data.isInstanceMember
        ? _sourceImportPrefix(fix)
        : _importPrefix(fix.node);
    return builder.importLibraryElement(libraryUri, prefix: prefix);
  }

  /// Replacement range of an instance or extension member access.
  ///
  /// If [replaceTarget] is true, the target is also replaced.
  // TODO(brianwilkinson): Maybe also handle setters<->one parameter functions
  // switching between `(target.)setter = e` and `(target.)method(e)`.
  _Data? _instanceInvocation(DataDrivenFix fix, SimpleIdentifier node) {
    var oldComponents = fix.element.components;
    if (oldComponents.isEmpty || node.name != oldComponents.first) {
      return null;
    }
    if (!replaceTarget && !_canKeepInstanceTarget(fix, node)) {
      return null;
    }
    if (!_matchesAccessKind(fix.element.kind, node)) {
      return null;
    }
    if (replaceTarget && _isCascadedAccess(node)) {
      return null;
    }
    var rangeStart = replaceTarget
        ? _simpleIdentifierRangeStartWithTarget(node)
        : node;
    var isGetter = switch (node.writeOrReadElement) {
      GetterElement() => true,
      MethodElement() => false,
      _ =>
        fix.element.kind == ElementKind.getterKind ||
            fix.element.kind == ElementKind.fieldKind,
    };
    return switch ((isGetter, newElement.kind)) {
      (true, ElementKind.methodKind) => _Data(
        range.startEnd(rangeStart, node),
        suffix: '()',
        isInstanceMember: true,
      ),
      (false, ElementKind.getterKind) => _methodToGetterData(node, rangeStart),
      _ => _Data(range.startEnd(rangeStart, node), isInstanceMember: true),
    };
  }

  bool _isInstanceAccess(SimpleIdentifier node, DataDrivenFix fix) {
    if (node.writeOrReadElement case var element?) {
      return element is ExecutableElement &&
          !element.isStatic &&
          element is! ConstructorElement;
    }
    var oldElement = fix.element;
    if (oldElement.isStatic ||
        oldElement.components.length != 2 ||
        oldElement.kind == ElementKind.constructorKind ||
        oldElement.kind == ElementKind.constantKind) {
      return false;
    }
    return _isInstanceTarget(_realTargetOf(node));
  }

  bool _matchesAccessKind(ElementKind oldKind, SimpleIdentifier node) {
    var newKind = newElement.kind;
    if (_isWriteAccess(node)) {
      return (oldKind == ElementKind.setterKind ||
              oldKind == ElementKind.fieldKind) &&
          (newKind == ElementKind.setterKind ||
              newKind == ElementKind.fieldKind ||
              newKind == ElementKind.variableKind);
    }
    if (oldKind == ElementKind.setterKind ||
        newKind == ElementKind.setterKind) {
      return false;
    }
    return node.writeOrReadElement is! MethodElement ||
        oldKind == ElementKind.methodKind;
  }

  _Data? _methodToGetterData(SimpleIdentifier node, AstNode rangeStart) {
    var parent = node.parent;
    if (parent is! MethodInvocation || node != parent.methodName) {
      return null;
    }
    var argumentList = parent.argumentList;
    if (argumentList.arguments.isNotEmpty || parent.typeArguments != null) {
      return null;
    }
    var argumentTypes = parent.typeArgumentTypes;
    if (argumentTypes != null && argumentTypes.isNotEmpty) {
      return null;
    }
    return _Data(
      range.startEnd(rangeStart, argumentList),
      isInstanceMember: true,
    );
  }

  /// Finds a range for a node that includes its target.
  ///
  /// For a [NamedType], it does not include type arguments or `?`.
  SourceRange? _rangeWithTarget(AstNode node, DataDrivenFix fix) {
    var elements = fix.element.components;
    if (elements.isEmpty) return null;
    var simpleName = elements[0];
    return switch (node) {
      SimpleStringLiteral(:var stringValue) when stringValue == simpleName =>
        range.startOffsetEndOffset(node.contentsOffset, node.contentsEnd),
      SimpleIdentifier() when _matchesStaticSimpleIdentifier(node, elements) =>
        range.startEnd(_simpleIdentifierRangeStartWithTarget(node), node),
      PrefixedIdentifier(:var prefix) => range.startEnd(prefix, node),
      ConstructorName(:var name, :var type) => range.node(
        name != null ? node : type,
      ),
      NamedType() => _namedTypeRange(node, elements),
      _ => null,
    };
  }

  void _writeArguments(DartEditBuilder builder, DataDrivenFix fix, _Data data) {
    if (arguments.isNotEmpty) {
      var templateContext = TemplateContext(fix.node, fix.utils);
      builder.write('(');
      arguments.first.writeOn(builder, templateContext);
      for (var i = 1; i < arguments.length; i++) {
        builder.write(',');
        arguments[i].writeOn(builder, templateContext);
      }
      builder.write(')');
    } else if (data.suffix case var suffix?) {
      builder.write(suffix);
    }
  }

  static String? _importPrefix(AstNode node) => switch (node) {
    NamedType(:var importPrefix) ||
    ConstructorName(type: NamedType(:var importPrefix)) ||
    ExtensionOverride(
      :var importPrefix,
    ) => _prefixElementName(importPrefix?.element),
    PrefixedIdentifier(:var prefix) => _prefixElementName(prefix.element),
    SimpleIdentifier(:var parent) => _parentImportPrefix(parent),
    _ => null,
  };

  static bool _isCascadedAccess(SimpleIdentifier node) => switch (node.parent) {
    PropertyAccess(:var isCascaded, :var propertyName)
        when node == propertyName =>
      isCascaded,
    MethodInvocation(:var isCascaded, :var methodName)
        when node == methodName =>
      isCascaded,
    _ => false,
  };

  static bool _isInstanceTarget(Expression? target) {
    if (target == null) return false;
    if (target is ExtensionOverride) return true;
    if (target is Identifier) {
      var element = target.element;
      if (element == null ||
          element is ExtensionElement ||
          element is InterfaceElement ||
          element is PrefixElement ||
          element is TypeAliasElement) {
        return false;
      }
    }
    var type = target.staticType;
    return type != null && type is! InvalidType;
  }

  static bool _isWriteAccess(SimpleIdentifier node) {
    AstNode expr = switch (node.parent) {
      PrefixedIdentifier parent when node == parent.identifier => parent,
      PropertyAccess parent when node == parent.propertyName => parent,
      _ => node,
    };
    return switch (expr.parent) {
      AssignmentExpression(:var leftHandSide) => leftHandSide == expr,
      PrefixExpression(:var operand, :var operator) =>
        operand == expr && operator.type.isIncrementOperator,
      PostfixExpression(:var operand, :var operator) =>
        operand == expr && operator.type.isIncrementOperator,
      _ => false,
    };
  }

  static bool _matchesStaticSimpleIdentifier(
    SimpleIdentifier node,
    List<String> elements,
  ) {
    var simpleName = elements[0];
    if (node.name != (simpleName.isNotEmpty ? simpleName : elements[1])) {
      return false;
    }
    if (elements.length == 2 &&
        simpleName.isNotEmpty &&
        _realTargetOf(node) == null &&
        _simpleIdentifierRangeStartWithTarget(node) == node) {
      return node.enclosingInstanceElement?.name == elements[1];
    }
    return true;
  }

  static SourceRange? _namedTypeRange(NamedType node, List<String> elements) {
    var simpleName = elements[0];
    var typeName = node.name.lexeme;
    var isDirectType =
        elements.length == 1 && simpleName == typeName ||
        elements.length == 2 && simpleName.isEmpty && elements[1] == typeName;
    if (isDirectType) {
      // Omit trailing type parameters and/or `?`,
      // only include import prefix and type name.
      return range.startEnd(node, node.name);
    }
    if (elements.length != 2 || elements[1] != typeName) {
      return null;
    }
    // Static accesses or named constructors on a deprecated type.
    return switch (node.parent) {
      ConstructorName parent when parent.name?.name == simpleName => range.node(
        parent,
      ),
      MethodInvocation parent when parent.methodName.name == simpleName =>
        range.startEnd(node, parent.methodName),
      PropertyAccess parent when parent.propertyName.name == simpleName =>
        range.startEnd(node, parent.propertyName),
      _ => null,
    };
  }

  static String? _parentImportPrefix(AstNode? parent) => switch (parent) {
    NamedType(:var importPrefix) ||
    ConstructorName(type: NamedType(:var importPrefix)) ||
    ExtensionOverride(:var importPrefix) ||
    MethodInvocation(target: ExtensionOverride(:var importPrefix)) ||
    PropertyAccess(
      target: ExtensionOverride(:var importPrefix),
    ) => _prefixElementName(importPrefix?.element),
    PrefixedIdentifier(:var prefix) ||
    Annotation(name: PrefixedIdentifier(:var prefix)) ||
    MethodInvocation(target: SimpleIdentifier prefix) ||
    MethodInvocation(target: PrefixedIdentifier(:var prefix)) ||
    PropertyAccess(target: SimpleIdentifier prefix) ||
    PropertyAccess(
      target: PrefixedIdentifier(:var prefix),
    ) => _prefixElementName(prefix.element),
    _ => null,
  };

  static String? _prefixElementName(Element? element) =>
      element is PrefixElement && !element.fragments.any((f) => f.isDeferred)
      ? element.name
      : null;

  static Expression? _realTargetOf(SimpleIdentifier node) =>
      switch (node.parent) {
        PrefixedIdentifier(:var prefix, :var identifier)
            when node == identifier =>
          prefix,
        PropertyAccess(:var realTarget, :var propertyName)
            when node == propertyName =>
          realTarget,
        MethodInvocation(:var realTarget, :var methodName)
            when node == methodName =>
          realTarget,
        _ => null,
      };

  // Find the import element of `libraryUri`.
  static Uri _selectImportUri(
    DartFileEditBuilder builder,
    List<Uri> libraryUris,
  ) {
    assert(libraryUris.isNotEmpty);
    for (var uri in libraryUris) {
      if (builder.importsLibrary(uri)) return uri;
    }
    return libraryUris.first;
  }

  /// The start of any target of a static name, or the name itself.
  ///
  /// If the name has a static target or prefix, it should be included in the
  /// range, otherwise just start at the node itself.
  /// This checks any parent node which can contain a [SimpleIdentifier],
  /// where that identifier can be the target of a static access,
  /// and it then includes all prior tokens of the expression.
  /// Some nodes may contain more than one [SimpleIdentifier],
  /// but they can all be handled by finding the start of the expression.
  /// (Can't just use the start of the parent node, since that can include
  /// metadata.)
  ///
  static AstNode _simpleIdentifierRangeStartWithTarget(SimpleIdentifier node) {
    var parent = node.parent;
    if (parent is MethodInvocation) {
      // Correct whether `node` is `parent.target` or `parent.methodName`.
      // The `target` can be `null` if the access is a cascade selector.
      // In that case, we cannot replace the target.
      // Also, `parent.operator` must be `.` for a static access.
      return parent.target ?? node;
    } else if (parent is PropertyAccess) {
      // Correct whether `node` is `parent.target` or `parent.propertyName`.
      // The `target` can be `null` if the access is a cascade selector.
      // Also, `parent.operator` must be `.` for a static access.
      return parent.target ?? node;
    } else if (parent is PrefixedIdentifier) {
      // Correct whether `node` is `parent.prefix` or `parent.identifier`.
      return parent.prefix;
    } else if (parent is ConstructorName) {
      // Correct whether `node` is `parent.type` or `parent.name`.
      // TODO(brianwilkinson): When replacing a named constructor, retain the type arguments.
      return parent.type;
    } else if (parent is Annotation) {
      // Correct whether `node` is `parent.prefix` or `parent.constructorName`.
      return parent.name;
    } else if (parent is DotShorthandConstructorInvocation ||
        parent is DotShorthandInvocation ||
        parent is DotShorthandPropertyAccess) {
      // Will insert a non-dot-shorthand reference to the new value.
      return parent!;
    }
    // Nothing before the node.
    return node;
  }

  static String? _sourceImportPrefix(DataDrivenFix fix) {
    var sourceUris = fix.element.libraryUris;
    String? prefix;
    for (var import
        in fix.unitResult.libraryElement.firstFragment.libraryImports) {
      if (!sourceUris.contains(import.importedLibrary?.uri)) continue;
      var prefixFragment = import.prefix;
      if (prefixFragment == null || prefixFragment.isDeferred) return null;
      var importPrefix = prefixFragment.element.name;
      if (importPrefix == null || (prefix != null && prefix != importPrefix)) {
        return null;
      }
      prefix = importPrefix;
    }
    return prefix;
  }
}

/// The data about a reference to an element that's been replaced.
class _Data {
  final SourceRange referenceRange;

  /// Written after the reference, if not `null`.
  ///
  /// Used to add `()` when replacing a getter with a function.
  final String? suffix;

  final bool isInstanceMember;

  new(this.referenceRange, {this.suffix, this.isInstanceMember = false});
}
