// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:meta/meta.dart';

extension ClassElement2Extension on ClassElement2 {
  ClassElement get asElement {
    return firstFragment as ClassElement;
  }
}

extension ClassElementExtension on ClassElement {
  ClassElement2 get asElement2 {
    return (this as ClassElementImpl).element;
  }
}

extension CompilationUnitElementExtension on CompilationUnitElement {
  LibraryFragment get asElement2 {
    return this as LibraryFragment;
  }

  /// Returns this library fragment, and all its enclosing fragments.
  List<CompilationUnitElement> get withEnclosing {
    var result = <CompilationUnitElement>[];
    var current = this;
    while (true) {
      result.add(current);
      if (current.enclosingElement3 case var enclosing?) {
        current = enclosing;
      } else {
        break;
      }
    }
    return result;
  }
}

extension ConstructorElement2Extension on ConstructorElement2 {
  ConstructorElement get asElement {
    return baseElement.firstFragment as ConstructorElement;
  }
}

extension ConstructorElementExtension on ConstructorElement {
  ConstructorElement2 get asElement2 {
    return switch (this) {
      ConstructorFragment(:var element) => element,
      ConstructorMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension Element2Extension on Element2 {
  List<ElementAnnotation> get metadata {
    if (this case Annotatable annotatable) {
      return annotatable.metadata2.annotations;
    }
    return [];
  }
}

extension Element2OrNullExtension on Element2? {
  Element? get asElement {
    var self = this;
    switch (self) {
      case null:
        return null;
      case ConstructorElementImpl2():
        return self.firstFragment as Element;
      case DynamicElementImpl():
        return self;
      case ExecutableMember():
        return self.declaration as Element;
      case FieldElementImpl2():
        return self.firstFragment as Element;
      case FieldMember():
        return self.declaration as Element;
      case FormalParameterElement element2:
        return element2.asElement;
      case GetterElementImpl():
        return self.firstFragment as Element;
      case LabelElementImpl2 element2:
        return element2.asElement;
      case LibraryElementImpl():
        return self as Element;
      case LocalFunctionElementImpl():
        return self.wrappedElement as Element;
      case LocalVariableElementImpl2():
        return self.wrappedElement as Element;
      case MethodElementImpl2():
        return self.firstFragment as Element;
      case MultiplyDefinedElementImpl2 element2:
        return element2.asElement;
      case NeverElementImpl2():
        return NeverElementImpl.instance;
      case PrefixElement2 element2:
        return element2.asElement;
      case SetterElementImpl():
        return self.firstFragment as Element;
      case TopLevelFunctionElementImpl():
        return self.firstFragment as Element;
      case TopLevelVariableElementImpl2():
        return self.firstFragment as Element;
      case TypeDefiningElement2():
        return self.firstFragment as Element;
      default:
        throw UnsupportedError('Unsupported type: $runtimeType');
    }
  }
}

extension ElementExtension on Element {
  // TODO(scheglov): Maybe just add to `Element`?
  Element? get augmentation {
    if (this case AugmentableElement augmentable) {
      return augmentable.augmentation;
    }
    return null;
  }

  /// Whether the element is effectively [internal].
  bool get isInternal {
    if (hasInternal) {
      return true;
    }
    if (this case PropertyAccessorElement accessor) {
      var variable = accessor.variable2;
      if (variable != null && variable.hasInternal) {
        return true;
      }
    }
    return false;
  }

  /// Whether the element is effectively [protected].
  bool get isProtected {
    var self = this;
    if (self is PropertyAccessorElement &&
        self.enclosingElement3 is InterfaceElement) {
      if (self.hasProtected) {
        return true;
      }
      var variable = self.variable2;
      if (variable != null && variable.hasProtected) {
        return true;
      }
    }
    if (self is MethodElement &&
        self.enclosingElement3 is InterfaceElement &&
        self.hasProtected) {
      return true;
    }
    return false;
  }

  /// Whether the element is effectively [visibleForTesting].
  bool get isVisibleForTesting {
    if (hasVisibleForTesting) {
      return true;
    }
    if (this case PropertyAccessorElement accessor) {
      var variable = accessor.variable2;
      if (variable != null && variable.hasVisibleForTesting) {
        return true;
      }
    }
    return false;
  }

  List<Element> get withAugmentations {
    var result = <Element>[];
    Element? current = this;
    while (current != null) {
      result.add(current);
      current = current.augmentation;
    }
    return result;
  }
}

extension ElementImplExtension on ElementImpl {
  AnnotationImpl annotationAst(int index) {
    return metadata[index].annotationAst;
  }
}

extension ElementOrNullExtension on Element? {
  Element2? get asElement2 {
    var self = this;
    if (self == null) {
      return null;
    } else if (self is DynamicElementImpl) {
      return DynamicElementImpl2.instance;
    } else if (self is ExtensionElementImpl) {
      return (self as ExtensionFragment).element;
    } else if (self is ExecutableMember) {
      return self as ExecutableElement2;
    } else if (self is FieldMember) {
      return self as FieldElement2;
    } else if (self is FieldElementImpl) {
      return (self as FieldFragment).element;
    } else if (self is FunctionElementImpl) {
      if (self.enclosingElement3 is! CompilationUnitElement) {
        // TODO(scheglov): update `FunctionElementImpl.element` return type?
        return self.element;
      } else {
        return (self as Fragment).element;
      }
    } else if (self is InterfaceElementImpl) {
      return self.element;
    } else if (self is LabelElementImpl) {
      return self.element2;
    } else if (self is LibraryElementImpl) {
      return self;
    } else if (self is LocalVariableElementImpl) {
      return self.element;
    } else if (self is MultiplyDefinedElementImpl) {
      return MultiplyDefinedElementImpl2(
        self.libraryFragment,
        self.name,
        self.conflictingElements.map((e) => e.asElement2).nonNulls.toList(),
      );
    } else if (self is NeverElementImpl) {
      return NeverElementImpl2.instance;
    } else if (self is ParameterMember) {
      return self;
    } else if (self is PrefixElementImpl) {
      return self.element2;
    } else if (self is LibraryImportElementImpl ||
        self is LibraryExportElementImpl ||
        self is PartElementImpl) {
      // There is no equivalent in the new element model.
      return null;
    } else {
      return (self as Fragment?)?.element;
    }
  }
}

extension EnumElementExtension on EnumElement {
  EnumElement2 get asElement2 {
    return (this as EnumElementImpl).element;
  }
}

extension ExecutableElement2Extension on ExecutableElement2 {
  ExecutableElement get asElement {
    return firstFragment as ExecutableElement;
  }
}

extension ExecutableElement2OrNullExtension on ExecutableElement2? {
  ExecutableElement? get asElement {
    return this?.asElement;
  }
}

extension ExecutableElementExtension on ExecutableElement {
  ExecutableElement2 get asElement2 {
    return switch (this) {
      ExecutableFragment(:var element) => element,
      ExecutableMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension ExecutableElementOrNullExtension on ExecutableElement? {
  ExecutableElement2? get asElement2 {
    return this?.asElement2;
  }
}

extension ExtensionElementExtension on ExtensionElement {
  ExtensionElement2 get asElement2 {
    return (this as ExtensionElementImpl).element;
  }
}

extension FieldElementExtension on FieldElement {
  FieldElement2 get asElement2 {
    return switch (this) {
      FieldFragment(:var element) => element,
      FieldMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension FormalParameterExtension on FormalParameterElement {
  ParameterElement get asElement {
    return firstFragment as ParameterElement;
  }

  void appendToWithoutDelimiters(
    StringBuffer buffer, {
    @Deprecated('Only non-nullable by default mode is supported')
    bool withNullability = true,
  }) {
    buffer.write(
      type.getDisplayString(
        // ignore:deprecated_member_use_from_same_package
        withNullability: withNullability,
      ),
    );
    buffer.write(' ');
    buffer.write(displayName);
    if (defaultValueCode != null) {
      buffer.write(' = ');
      buffer.write(defaultValueCode);
    }
  }
}

extension InterfaceElement2Extension on InterfaceElement2 {
  InterfaceElement get asElement {
    return firstFragment as InterfaceElement;
  }
}

extension InterfaceElementExtension on InterfaceElement {
  InterfaceElement2 get asElement2 {
    return (this as InterfaceElementImpl).element;
  }
}

extension InterfaceTypeExtension on InterfaceType {
  MethodElement2? getMethod2(String name) {
    return getMethod(name)?.asElement2;
  }
}

extension LabelElement2Extension on LabelElement2 {
  LabelElement get asElement {
    return firstFragment as LabelElement;
  }
}

extension LibraryElement2Extension on LibraryElement2 {
  LibraryElement get asElement {
    return this as LibraryElement;
  }
}

extension LibraryElementExtension on LibraryElement {
  LibraryElement2 get asElement2 {
    return this as LibraryElement2;
  }
}

extension LibraryExportElementExtension on LibraryExportElement {
  LibraryExport get asElement2 {
    var index = enclosingElement3.libraryExports.indexOf(this);
    return enclosingElement3.asElement2.libraryExports2[index];
  }
}

extension LibraryFragmentExtension on LibraryFragment {
  /// Returns a list containing this library fragment and all of its enclosing
  /// fragments.
  List<LibraryFragment> get withEnclosing2 {
    var result = <LibraryFragment>[];
    var current = this;
    while (true) {
      result.add(current);
      if (current.enclosingFragment case var enclosing?) {
        current = enclosing;
      } else {
        break;
      }
    }
    return result;
  }
}

extension LibraryImportElementExtension on LibraryImportElement {
  LibraryImport get asElement2 {
    var index = enclosingElement3.libraryImports.indexOf(this);
    return enclosingElement3.asElement2.libraryImports2[index];
  }
}

extension ListOfTypeParameterElementExtension on List<TypeParameterElement> {
  List<TypeParameterType> instantiateNone() {
    return map((e) {
      return e.instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }).toList();
  }
}

extension MethodElement2Extension on MethodElement2 {
  MethodElement get asElement {
    return baseElement.firstFragment as MethodElement;
  }
}

extension MethodElementExtension on MethodElement {
  MethodElement2 get asElement2 {
    return switch (this) {
      MethodFragment(:var element) => element,
      MethodMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension MixinElementExtension on MixinElement {
  MixinElement2 get asElement2 {
    return (this as MixinElementImpl).element;
  }
}

extension ParameterElementExtension on ParameterElement {
  FormalParameterElement get asElement2 {
    return switch (this) {
      FormalParameterFragment(:var element) => element,
      ParameterMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }

  ParameterElementImpl get declarationImpl {
    return declaration as ParameterElementImpl;
  }
}

extension PrefixElement2Extension on PrefixElement2 {
  PrefixElement get asElement {
    return (this as PrefixElementImpl2).asElement;
  }
}

extension PrefixElementExtension on PrefixElement {
  PrefixElement2 get asElement2 {
    return (this as PrefixElementImpl).element2;
  }
}

extension PropertyAccessorElementExtension on PropertyAccessorElement {
  PropertyAccessorElement2 get asElement2 {
    return switch (this) {
      PropertyAccessorFragment(:var element) => element,
      PropertyAccessorMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension TopLevelVariableElement2Extension on TopLevelVariableElement2 {
  TopLevelVariableElement get asElement {
    return baseElement.firstFragment as TopLevelVariableElement;
  }
}

extension TopLevelVariableElementExtension on TopLevelVariableElement {
  TopLevelVariableElement2 get asElement2 {
    return (this as TopLevelVariableElementImpl).element;
  }
}

extension TypeParameterElement2Extension on TypeParameterElement2 {
  TypeParameterElement get asElement {
    return firstFragment as TypeParameterElement;
  }
}
