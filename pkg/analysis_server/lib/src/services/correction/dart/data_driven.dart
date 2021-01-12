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
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:meta/meta.dart';

class DataDriven extends MultiCorrectionProducer {
  /// The transform sets used by the current test.
  @visibleForTesting
  static List<TransformSet> transformSetsForTests;

  @override
  Iterable<CorrectionProducer> get producers sync* {
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
    var components = _computeComponents();
    if (components == null) {
      // If we couldn't compute the components it's because the node doesn't
      // represent an element that can be transformed.
      return;
    }
    var matcher = ElementMatcher(
        importedUris: importedUris,
        components: components,
        kinds: _kindsForNode(node));
    for (var set in _availableTransformSetsForLibrary(library)) {
      for (var transform
          in set.transformsFor(matcher, applyingBulkFixes: applyingBulkFixes)) {
        yield DataDrivenFix(transform);
      }
    }
  }

  /// Return the transform sets that are available for fixing issues in the
  /// given [library].
  List<TransformSet> _availableTransformSetsForLibrary(LibraryElement library) {
    if (transformSetsForTests != null) {
      return transformSetsForTests;
    }
    return TransformSetManager.instance.forLibrary(library);
  }

  /// Return the components for the element associated with the given [node] by
  /// looking at the parent of the [node].
  List<String> _componentsFromParent(AstNode node) {
    var parent = node.parent;
    if (parent is ArgumentList) {
      parent = parent.parent;
    }
    if (parent is Annotation) {
      return [parent.constructorName?.name ?? '', parent.name.name];
    } else if (parent is ExtensionOverride) {
      return [parent.extensionName.name];
    } else if (parent is InstanceCreationExpression) {
      var constructorName = parent.constructorName;
      return [constructorName.name?.name ?? '', constructorName.type.name.name];
    } else if (parent is MethodInvocation) {
      var target = _nameOfTarget(parent.realTarget);
      if (target != null) {
        return [parent.methodName.name, target];
      }
      var ancestor = parent.parent;
      while (ancestor != null) {
        if (ancestor is ClassOrMixinDeclaration) {
          return [parent.methodName.name, ancestor.name.name];
        } else if (ancestor is ExtensionDeclaration) {
          return [parent.methodName.name, ancestor.name.name];
        }
        ancestor = ancestor.parent;
      }
      return [parent.methodName.name];
    } else if (parent is RedirectingConstructorInvocation) {
      var ancestor = parent.parent;
      if (ancestor is ConstructorDeclaration) {
        return [parent.constructorName?.name ?? '', ancestor.returnType.name];
      }
    } else if (parent is SuperConstructorInvocation) {
      var ancestor = parent.parent;
      if (ancestor is ConstructorDeclaration) {
        return [parent.constructorName?.name ?? '', ancestor.returnType.name];
      }
    }
    return null;
  }

  /// Return the components of the path of the element associated with the
  /// diagnostic. The components are ordered from the most local to the most
  /// global. For example, for a constructor this would be the name of the
  /// constructor followed by the name of the class in which the constructor is
  /// declared (with an empty string for the unnamed constructor).
  List<String> _computeComponents() {
    var node = this.node;
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is Label && parent.parent is NamedExpression) {
        // The parent of the named expression is an argument list. Because we
        // don't represent parameters as elements, the element we need to match
        // against is the invocation containing those arguments.
        return _componentsFromParent(parent.parent.parent);
      } else if (parent is TypeName && parent.parent is ConstructorName) {
        return ['', node.name];
      } else if (parent is MethodInvocation) {
        return _componentsFromParent(node);
      }
      return [node.name];
    } else if (node is PrefixedIdentifier) {
      var parent = node.parent;
      if (parent is TypeName && parent.parent is ConstructorName) {
        return ['', node.identifier.name];
      }
      return [node.identifier.name];
    } else if (node is ConstructorName) {
      return [node.name.name];
    } else if (node is NamedType) {
      return [node.name.name];
    } else if (node is TypeArgumentList) {
      return _componentsFromParent(node);
    } else if (node is ArgumentList) {
      return _componentsFromParent(node);
    } else if (node?.parent is ArgumentList) {
      return _componentsFromParent(node.parent);
    }
    return null;
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

  /// Return the name of the class associated with the given [target].
  String _nameOfTarget(Expression target) {
    if (target is SimpleIdentifier) {
      var type = target.staticType;
      if (type != null) {
        if (type is InterfaceType) {
          return type.element.name;
        } else if (type.isDynamic) {
          // The name is likely to be undefined.
          return target.name;
        }
        return null;
      }
      return target.name;
    } else if (target != null) {
      var type = target.staticType;
      if (type is InterfaceType) {
        return type.element.name;
      }
      return null;
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
