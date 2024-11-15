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

extension CompilationUnitElementExtension on CompilationUnitElement {
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

extension Element2OrNullExtension on Element2? {
  Element? get asElement {
    var self = this;
    switch (self) {
      case ConstructorElementImpl2():
        return self.firstFragment as Element;
      case DynamicElementImpl():
        return self;
      case ExecutableMember():
        return self.declaration as Element;
      case FieldElementImpl2():
        return self.firstFragment as Element;
      case FormalParameterElementImpl():
        return self.firstFragment as Element;
      case GetterElementImpl():
        return self.firstFragment as Element;
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
      case PrefixElementImpl():
        return self;
      case SetterElementImpl():
        return self.firstFragment as Element;
      case TopLevelFunctionElementImpl():
        return self.firstFragment as Element;
      case TopLevelVariableElementImpl2():
        return self.firstFragment as Element;
      case TypeDefiningElement2():
        return self.firstFragment as Element;
      default:
        return null;
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

extension FormalParameterExtension on FormalParameterElement {
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

extension ListOfTypeParameterElementExtension on List<TypeParameterElement> {
  List<TypeParameterType> instantiateNone() {
    return map((e) {
      return e.instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }).toList();
  }
}

extension ParameterElementExtension on ParameterElement {
  ParameterElementImpl get declarationImpl {
    return declaration as ParameterElementImpl;
  }
}

extension TypeParameterElement2Extension on TypeParameterElement2 {
  TypeParameterElement get asElement {
    return firstFragment as TypeParameterElement;
  }
}
