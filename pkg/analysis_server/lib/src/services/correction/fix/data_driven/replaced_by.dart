// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart' hide ElementKind;
import 'package:analyzer/source/source_range.dart';
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
  ReplacedBy({
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
    ImportLibraryElementResult? importElement;
    var libraryUris = newElement.libraryUris;
    if (libraryUris.isNotEmpty) {
      // A library URI from `libraryUris`, either one already imported,
      // or the first one in the list.
      var libraryUri = _selectImportUri(builder, libraryUris);
      importElement = builder.importLibraryElement(libraryUri);
    }
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
      if (arguments.isNotEmpty) {
        var templateContext = TemplateContext(fix.node, fix.utils);
        builder.write('(');
        arguments.first.writeOn(builder, templateContext);
        for (int i = 1; i < arguments.length; i++) {
          builder.write(',');
          arguments[i].writeOn(builder, templateContext);
        }
        builder.write(')');
      } else if (data.suffix case var suffix?) {
        builder.write(suffix);
      }
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
    if (node is SimpleIdentifier) {
      // Include prefix if prefixed.
      var element = node.element;
      if (element is ExecutableElement &&
          !element.isStatic &&
          element is! ConstructorElement) {
        var result = _instanceInvocation(fix, node, element, replaceTarget);
        return result;
      }
    }
    var sourceRange = _rangeWithTarget(node, fix);
    if (sourceRange != null) {
      return _Data(sourceRange);
    }
    return null;
  }

  /// Replacement range of a function, getter or setter invocation.
  ///
  /// If [replaceTarget] is true, the target is also replaced.
  /// That should always be the case for static functions, and is true
  /// for instance functions if the fix is set to replace the target.
  ///
  // TODO(brianwilkinson): Maybe also handle setters<->one parameter functions
  // switching between `(target.)setter = e` and `(target.)method(e)`.
  _Data? _instanceInvocation(
    DataDrivenFix fix,
    SimpleIdentifier node,
    ExecutableElement element,
    bool replaceTarget,
  ) {
    var newKind = newElement.kind;
    String? suffix;
    SourceRange? referenceRange;
    if (newKind == ElementKind.methodKind && element is GetterElement) {
      // Convert from getter to method with no type arguments or arguments.
      suffix = '()';
      AstNode rangeStart;
      if (replaceTarget) {
        rangeStart = _simpleIdentifierRangeStartWithTarget(node);
      } else {
        rangeStart = node;
      }
      referenceRange = range.startEnd(rangeStart, node);
    } else if (newKind == ElementKind.getterKind) {
      // Convert from function call to getter,
      // only if no arguments or type arguments.
      var parent = node.parent;
      if (parent is MethodInvocation) {
        var argumentList = parent.argumentList;
        if (argumentList.arguments.isNotEmpty) {
          return null;
        }
        var argumentTypes = parent.typeArgumentTypes;
        if (argumentTypes != null && argumentTypes.isNotEmpty) {
          return null;
        }
        if (replaceTarget) {
          var rangeStart = _simpleIdentifierRangeStartWithTarget(node);
          referenceRange = range.startEnd(rangeStart, argumentList);
        } else {
          referenceRange = range.startEnd(node, argumentList);
        }
      }
    }

    if (referenceRange == null) {
      if (replaceTarget) {
        var rangeStart = _simpleIdentifierRangeStartWithTarget(node);
        referenceRange = range.startEnd(rangeStart, node);
      } else {
        return null;
      }
    }
    return _Data(referenceRange, suffix: suffix, isInstanceMember: true);
  }

  /// Finds a range for a node that includes its target.
  ///
  /// For a [NamedType], it does not include type arguments or `?`.
  SourceRange? _rangeWithTarget(AstNode node, DataDrivenFix fix) {
    var elements = fix.element.components;
    if (elements.isEmpty) return null;
    var simpleName = elements[0];
    if (node is SimpleIdentifier) {
      if (node.name != (simpleName.isNotEmpty ? simpleName : elements[1])) {
        return null;
      }
      var rangeStart = _simpleIdentifierRangeStartWithTarget(node);
      return range.startEnd(rangeStart, node);
    } else if (node is PrefixedIdentifier) {
      return range.startEnd(node.prefix, node);
    } else if (node is ConstructorName) {
      // TODO(brianwilkinson): Remember the type arguments, so they can be retained when
      // replacing a named constructor, or placed correctly if replacing with
      // a named constructor.
      if (node.name != null) {
        return range.node(node);
      } else {
        // Return the type's names only (omit/retain type arguments).
        return range.node(node.type);
      }
    } else if (node is NamedType) {
      var typeName = node.name.lexeme;
      if (elements.length == 1 && simpleName == typeName ||
          elements.length == 2 &&
              simpleName.isEmpty &&
              elements[1] == typeName) {
        // Omit trailing type parameters and/or `?`,
        // only include import prefix and type name.
        return range.startEnd(node, node.name);
      } else {
        // Check if it's a static member or constructor of a deprecated type.
        if (elements.length == 2 && elements[1] == typeName) {
          // And elements[0] is not empty.

          // Static accesses on a deprecated type.
          var parent = node.parent;
          if (parent is ConstructorName && parent.name?.name == simpleName) {
            // TODO(brianwilkinson): Retain type arguments.
            return range.node(parent);
          }
          if (parent is MethodInvocation &&
              parent.methodName.name == simpleName) {
            return range.startEnd(node, parent.methodName);
          }
          if (parent is PropertyAccess &&
              parent.propertyName.name == simpleName) {
            return range.startEnd(node, parent.propertyName);
          }
        }
      }
    }
    return null;
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
  AstNode _simpleIdentifierRangeStartWithTarget(SimpleIdentifier node) {
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
}

/// The data about a reference to an element that's been replaced.
class _Data {
  final SourceRange referenceRange;

  /// Written after the reference, if not `null`.
  ///
  /// Used to add `()` when replacing a getter with a function.
  final String? suffix;

  final bool isInstanceMember;

  _Data(this.referenceRange, {this.suffix, this.isInstanceMember = false});
}
