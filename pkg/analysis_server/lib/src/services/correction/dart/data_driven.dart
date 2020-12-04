// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/code_template.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_matcher.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_manager.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart' show LibraryElement;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:meta/meta.dart';

class DataDriven extends MultiCorrectionProducer {
  /// The transform sets used by the current test.
  @visibleForTesting
  static List<TransformSet> transformSetsForTests;

  @override
  Iterable<CorrectionProducer> get producers sync* {
    var name = _name;
    var importedUris = <Uri>[];
    var library = resolvedResult.libraryElement;
    for (var importElement in library.imports) {
      // TODO(brianwilkerson) Filter based on combinators to help avoid making
      //  invalid suggestions.
      var uri = importElement.uri;
      if (uri != null) {
        // The [uri] is `null` if the literal string is not a valid URI.
        importedUris.add(Uri.parse(uri));
      }
    }
    var matcher = ElementMatcher(
        importedUris: importedUris, name: name, kinds: _kindsForNode(node));
    for (var set in _availableTransformSetsForLibrary(library)) {
      for (var transform
          in set.transformsFor(matcher, applyingBulkFixes: applyingBulkFixes)) {
        yield DataDrivenFix(transform);
      }
    }
  }

  /// Return the name of the element that was changed.
  String get _name {
    String nameFromParent(AstNode node) {
      var parent = node.parent;
      if (parent is MethodInvocation) {
        return parent.methodName.name;
      } else if (parent is InstanceCreationExpression) {
        var constructorName = parent.constructorName;
        if (constructorName.name != null) {
          return constructorName.name.name;
        }
        return constructorName.type.name.name;
      } else if (parent is ExtensionOverride) {
        return parent.extensionName.name;
      }
      return null;
    }

    var node = this.node;
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is Label && parent.parent is NamedExpression) {
        // The parent of the named expression is an argument list. Because we
        // don't represent parameters as elements, the element we need to match
        // against is the invocation containing those arguments.
        return nameFromParent(parent.parent.parent);
      }
      return node.name;
    } else if (node is ConstructorName) {
      return node.name.name;
    } else if (node is NamedType) {
      return node.name.name;
    } else if (node is TypeArgumentList) {
      return nameFromParent(node);
    } else if (node is ArgumentList) {
      return nameFromParent(node);
    }
    return null;
  }

  /// Return the transform sets that are available for fixing issues in the
  /// given [library].
  List<TransformSet> _availableTransformSetsForLibrary(LibraryElement library) {
    if (transformSetsForTests != null) {
      return transformSetsForTests;
    }
    return TransformSetManager.instance.forLibrary(library);
  }

  List<ElementKind> _kindsForNode(AstNode node, {AstNode child}) {
    if (node is ConstructorName) {
      return const [ElementKind.constructorKind];
    } else if (node is ExtensionOverride) {
      return const [ElementKind.extensionKind];
    } else if (node is InstanceCreationExpression) {
      return const [ElementKind.constructorKind];
    } else if (node is Label) {
      var argumentList = node.parent.parent;
      return _kindsForNode(argumentList.parent, child: argumentList);
    } else if (node is MethodInvocation) {
      assert(child != null);
      if (node.target == child) {
        return const [
          ElementKind.classKind,
          ElementKind.enumKind,
          ElementKind.mixinKind
        ];
      } else if (node.realTarget != null) {
        return const [ElementKind.constructorKind, ElementKind.methodKind];
      }
      return const [
        ElementKind.classKind,
        ElementKind.extensionKind,
        ElementKind.functionKind,
        ElementKind.methodKind
      ];
    } else if (node is NamedType) {
      var parent = node.parent;
      if (parent is ConstructorName && parent.name == null) {
        return const [ElementKind.classKind, ElementKind.constructorKind];
      }
      return const [
        ElementKind.classKind,
        ElementKind.enumKind,
        ElementKind.mixinKind,
        ElementKind.typedefKind
      ];
    } else if (node is PrefixedIdentifier) {
      if (node.prefix == child) {
        return const [
          ElementKind.classKind,
          ElementKind.enumKind,
          ElementKind.extensionKind,
          ElementKind.mixinKind,
          ElementKind.typedefKind
        ];
      }
      return const [
        ElementKind.fieldKind,
        ElementKind.getterKind,
        ElementKind.setterKind
      ];
    } else if (node is PropertyAccess) {
      return const [ElementKind.getterKind, ElementKind.setterKind];
    } else if (node is SimpleIdentifier) {
      return _kindsForNode(node.parent, child: node);
    }
    return null;
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static DataDriven newInstance() => DataDriven();
}

/// A correction processor that can make one of the possible change computed by
/// the [DataDriven] producer.
class DataDrivenFix extends CorrectionProducer {
  /// The transform being applied to implement this fix.
  final Transform _transform;

  DataDrivenFix(this._transform);

  /// Return a description of the element that was changed.
  ElementDescriptor get element => _transform.element;

  @override
  List<Object> get fixArguments => [_transform.title];

  @override
  FixKind get fixKind => DartFixKind.DATA_DRIVEN;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var changes = _transform.changesSelector
        .getChanges(TemplateContext.forInvocation(node, utils));
    if (changes == null) {
      return;
    }
    var data = <Object>[];
    for (var change in changes) {
      var result = change.validate(this);
      if (result == null) {
        return;
      }
      data.add(result);
    }
    await builder.addDartFileEdit(file, (builder) {
      for (var i = 0; i < changes.length; i++) {
        changes[i].apply(builder, this, data[i]);
      }
    });
  }
}
