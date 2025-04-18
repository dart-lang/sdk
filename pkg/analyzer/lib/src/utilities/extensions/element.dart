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
import 'package:analyzer/src/dart/element/type.dart';
import 'package:meta/meta.dart';

class MockLibraryImportElement implements Element2, PrefixFragment {
  final LibraryImportElementImpl import;

  MockLibraryImportElement(LibraryImport import)
      : import = import as LibraryImportElementImpl;

  @override
  LibraryElement2 get enclosingElement2 => library2;

  @override
  ElementKind get kind => ElementKind.IMPORT;

  @override
  LibraryElementImpl get library2 => libraryFragment.element;

  @override
  CompilationUnitElementImpl get libraryFragment => import.libraryFragment;

  @override
  String? get name3 => import.prefix2?.name2;

  @override
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
}

extension BindPatternVariableElementImpl2Extension
    on BindPatternVariableElementImpl2 {
  BindPatternVariableElementImpl get asElement {
    return firstFragment;
  }
}

extension BindPatternVariableElementImplExtension
    on BindPatternVariableElementImpl {
  BindPatternVariableElementImpl2 get asElement2 {
    return element;
  }
}

extension ClassElementImpl2Extension on ClassElementImpl2 {
  ClassElementImpl get asElement {
    return firstFragment;
  }
}

extension ClassElementImplExtension on ClassElementImpl {
  ClassElementImpl2 get asElement2 {
    return element;
  }
}

extension CompilationUnitElementImplExtension on CompilationUnitElementImpl {
  /// Returns this library fragment, and all its enclosing fragments.
  List<CompilationUnitElementImpl> get withEnclosing {
    var result = <CompilationUnitElementImpl>[];
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

extension ConstructorElementImpl2Extension on ConstructorElementImpl2 {
  ConstructorElementImpl get asElement {
    return lastFragment;
  }
}

extension ConstructorElementImplExtension on ConstructorElementImpl {
  ConstructorElementImpl2 get asElement2 {
    return element;
  }
}

extension ConstructorElementMixin2Extension on ConstructorElementMixin2 {
  ConstructorElementMixin get asElement {
    if (this case ConstructorMember member) {
      return member;
    }
    return (this as ConstructorElementImpl2).lastFragment;
  }
}

extension ConstructorElementMixinExtension on ConstructorElementMixin {
  ConstructorElementMixin2 get asElement2 {
    return switch (this) {
      ConstructorElementImpl(:var element) => element,
      ConstructorMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }

  ElementImpl? get enclosingElementImpl => enclosingElement3 as ElementImpl?;
}

extension Element2Extension on Element2 {
  /// Whether the element is effectively [internal].
  bool get isInternal {
    if (this case Annotatable annotatable) {
      if (annotatable.metadata2.hasInternal) {
        return true;
      }
    }
    if (this case PropertyAccessorElement2 accessor) {
      var variable = accessor.variable3;
      if (variable != null && variable.metadata2.hasInternal) {
        return true;
      }
    }
    return false;
  }

  /// Whether the element is effectively [protected].
  bool get isProtected {
    var self = this;
    if (self is PropertyAccessorElement2 &&
        self.enclosingElement2 is InterfaceElement2) {
      if (self.metadata2.hasProtected) {
        return true;
      }
      var variable = self.variable3;
      if (variable != null && variable.metadata2.hasProtected) {
        return true;
      }
    }
    if (self is MethodElement2 &&
        self.enclosingElement2 is InterfaceElement2 &&
        self.metadata2.hasProtected) {
      return true;
    }
    return false;
  }

  /// Whether the element is effectively [visibleForTesting].
  bool get isVisibleForTesting {
    if (this case Annotatable annotatable) {
      if (annotatable.metadata2.hasVisibleForTesting) {
        return true;
      }
    }
    if (this case PropertyAccessorElement2 accessor) {
      var variable = accessor.variable3;
      if (variable != null && variable.metadata2.hasVisibleForTesting) {
        return true;
      }
    }
    return false;
  }

  List<ElementAnnotation> get metadata {
    if (this case Annotatable annotatable) {
      return annotatable.metadata2.annotations;
    }
    return [];
  }
}

extension Element2OrNullExtension on Element2? {
  @Deprecated('Use Element2 instead')
  Element? get asElement {
    var self = this;
    switch (self) {
      case null:
        return null;
      case BindPatternVariableElementImpl2 element2:
        return element2.asElement;
      case ConstructorElementImpl2 element2:
        return element2.asElement;
      case DynamicElementImpl2():
        return self.firstFragment;
      case ExtensionElementImpl2 element2:
        return element2.asElement;
      case FieldElementImpl2 element2:
        return element2.asElement;
      case FieldMember():
        return self.declaration as Element;
      case FormalParameterElement element2:
        return element2.asElement;
      case GetterElementImpl element2:
        return element2.asElement;
      case LabelElementImpl2 element2:
        return element2.asElement;
      case LibraryElementImpl():
        return self as Element;
      case LibraryImportElementImpl():
        return self as Element;
      case LocalFunctionElementImpl element2:
        return element2.asElement;
      case LocalVariableElementImpl2():
        return self.wrappedElement as Element;
      case MethodElementImpl2 element2:
        return element2.asElement;
      case NeverElementImpl2():
        return NeverElementImpl.instance;
      case PrefixElement2 element2:
        return element2.asElement;
      case SetterElementImpl element2:
        return element2.asElement;
      case TopLevelFunctionElementImpl element2:
        return element2.asElement;
      case TopLevelVariableElementImpl2 element2:
        return element2.asElement;
      case TypeDefiningElement2():
        return self.firstFragment as Element;
      case MockLibraryImportElement():
        return self.import;
      default:
        throw UnsupportedError('Unsupported type: $runtimeType');
    }
  }
}

extension ElementImplExtension on ElementImpl {
  ElementImpl? get enclosingElementImpl => enclosingElement3;

  AnnotationImpl annotationAst(int index) {
    return metadata[index].annotationAst;
  }
}

@Deprecated('Use Element2 instead')
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
      if (self.enclosingElement3 is! CompilationUnitElementImpl) {
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

extension EnumElementImplExtension on EnumElementImpl {
  EnumElementImpl2 get asElement2 {
    return element;
  }
}

extension ExecutableElement2Extension on ExecutableElement2 {
  ExecutableElementOrMember get asElement {
    if (this case ExecutableMember member) {
      return member;
    }
    return firstFragment as ExecutableElementOrMember;
  }
}

extension ExecutableElementImpl2Extension on ExecutableElementImpl2 {
  ExecutableElementImpl get asElement {
    return lastFragment;
  }
}

extension ExecutableElementImplExtension on ExecutableElementImpl {
  ExecutableElementImpl2 get asElement2 {
    return element;
  }
}

extension ExecutableElementOrMemberExtension on ExecutableElementOrMember {
  ExecutableElement2OrMember get asElement2 {
    return switch (this) {
      ExecutableElementImpl(:var element) => element,
      ExecutableMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }

  ExecutableElementImpl get declarationImpl =>
      asElement2.baseElement.firstFragment as ExecutableElementImpl;

  ElementImpl get enclosingElementImpl =>
      asElement2.enclosingElement2!.firstFragment as ElementImpl;
}

extension ExtensionElementImpl2Extension on ExtensionElementImpl2 {
  ExtensionElementImpl get asElement {
    return firstFragment;
  }
}

extension ExtensionElementImplExtension on ExtensionElementImpl {
  ExtensionElementImpl2 get asElement2 {
    return element;
  }
}

extension ExtensionTypeElementImpl2Extension on ExtensionTypeElementImpl2 {
  ExtensionTypeElementImpl get asElement {
    return firstFragment;
  }
}

extension FieldElementImpl2Extension on FieldElementImpl2 {
  FieldElementImpl get asElement {
    return firstFragment;
  }
}

extension FieldElementOrMemberExtension on FieldElementOrMember {
  FieldElement2OrMember get asElement2 {
    return switch (this) {
      FieldElementImpl(:var element) => element,
      FieldMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension FormalParameterElementExtension on FormalParameterElement {
  @Deprecated(elementModelDeprecationMsg)
  ParameterElement get asElement {
    if (this case ParameterMember member) {
      return member;
    }
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

extension FormalParameterElementImplExtension on FormalParameterElementImpl {
  ParameterElementImpl get asElement {
    return firstFragment;
  }
}

extension FormalParameterElementMixinExtension on FormalParameterElementMixin {
  ParameterElementMixin get asElement {
    return switch (this) {
      FormalParameterElementImpl(:var firstFragment) => firstFragment,
      ParameterMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension GetterElementImplExtension on GetterElementImpl {
  PropertyAccessorElementImpl get asElement {
    return lastFragment;
  }
}

extension InstanceElementImpl2Extension on InstanceElementImpl2 {
  InstanceElementImpl get asElement {
    return firstFragment;
  }
}

extension InstanceElementImplExtension on InstanceElementImpl {
  InstanceElementImpl2 get asElement2 {
    return element;
  }
}

extension InterfaceElementImpl2Extension on InterfaceElementImpl2 {
  InterfaceElementImpl get asElement {
    return firstFragment;
  }
}

extension InterfaceElementImplExtension on InterfaceElementImpl {
  InterfaceElementImpl2 get asElement2 {
    return element;
  }
}

extension InterfaceTypeImplExtension on InterfaceTypeImpl {
  InterfaceElementImpl get elementImpl => element3.firstFragment;
}

extension JoinPatternVariableElementImplExtension
    on JoinPatternVariableElementImpl {
  JoinPatternVariableElementImpl2 get asElement2 {
    return element;
  }
}

extension LibraryElement2Extension on LibraryElement2 {
  @Deprecated('Use LibraryElement2 instead')
  LibraryElement get asElement {
    return this as LibraryElement;
  }
}

@Deprecated('Use LibraryElement2 instead')
extension LibraryElementExtension on LibraryElement {
  LibraryElement2 get asElement2 {
    return this as LibraryElement2;
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

extension ListOfTypeParameterElement2Extension on List<TypeParameterElement2> {
  List<TypeParameterType> instantiateNone() {
    return map((e) {
      return e.instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }).toList();
  }
}

extension LocalVariableElementImplExtension on LocalVariableElementImpl {
  LocalVariableElementImpl2 get asElement2 {
    return element;
  }
}

extension MethodElement2OrMemberExtension on MethodElement2OrMember {
  MethodElementOrMember get asElement {
    if (this case MethodMember member) {
      return member;
    }
    return (this as MethodElementImpl2).lastFragment;
  }
}

extension MethodElementImpl2Extension on MethodElementImpl2 {
  MethodElementImpl get asElement {
    return lastFragment;
  }
}

extension MethodElementImplExtension on MethodElementImpl {
  MethodElementImpl2 get asElement2 {
    return element;
  }
}

extension MethodElementOrMemberExtension on MethodElementOrMember {
  MethodElement2OrMember get asElement2 {
    return switch (this) {
      MethodElementImpl(:var element) => element,
      MethodMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension MixinElementImplExtension on MixinElementImpl {
  MixinElementImpl2 get asElement2 {
    return element;
  }
}

extension ParameterElementImplExtension on ParameterElementImpl {
  FormalParameterElementImpl get asElement2 {
    return element;
  }
}

extension ParameterElementMixinExtension on ParameterElementMixin {
  FormalParameterElementMixin get asElement2 {
    return switch (this) {
      ParameterElementImpl(:var element) => element,
      ParameterMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension PatternVariableElementImpl2Extension on PatternVariableElementImpl2 {
  PatternVariableElementImpl get asElement {
    return firstFragment;
  }
}

extension PatternVariableElementImplExtension on PatternVariableElementImpl {
  PatternVariableElementImpl2 get asElement2 {
    return element;
  }
}

extension PropertyAccessorElement2OrMemberExtension
    on PropertyAccessorElement2OrMember {
  PropertyAccessorElementOrMember get asElement {
    if (this case PropertyAccessorMember member) {
      return member;
    }
    return (this as PropertyAccessorElementImpl2).lastFragment;
  }
}

extension PropertyAccessorElementImplExtension on PropertyAccessorElementImpl {
  PropertyAccessorElementImpl2 get asElement2 {
    return element;
  }
}

extension PropertyAccessorElementOrMemberExtension
    on PropertyAccessorElementOrMember {
  PropertyAccessorElement2OrMember get asElement2 {
    return switch (this) {
      PropertyAccessorElementImpl(:var element) => element,
      PropertyAccessorMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension PropertyInducingElementExtension on PropertyInducingElement2 {
  bool get definesSetter {
    if (isConst) {
      return false;
    }
    if (isFinal) {
      return isLate && !hasInitializer;
    } else {
      return true;
    }
  }
}

extension SetterElementImplExtension on SetterElementImpl {
  PropertyAccessorElementImpl get asElement {
    return lastFragment;
  }
}

extension TopLevelFunctionElementImplExtension on TopLevelFunctionElementImpl {
  FunctionElementImpl get asElement {
    return lastFragment;
  }
}

extension TopLevelVariableElementImpl2Extension
    on TopLevelVariableElementImpl2 {
  TopLevelVariableElementImpl get asElement {
    return firstFragment;
  }
}

extension TypeAliasElementImpl2Extension on TypeAliasElementImpl2 {
  TypeAliasElementImpl get asElement {
    return firstFragment;
  }
}

extension TypeAliasElementImplExtension on TypeAliasElementImpl {
  TypeAliasElementImpl2 get asElement2 {
    return element;
  }
}

extension TypeParameterElement2Extension on TypeParameterElement2 {
  TypeParameterElementImpl2 freshCopy() {
    var fragment = TypeParameterElementImpl(
      name3 ?? '',
      -1,
    );
    fragment.bound = bound;
    return TypeParameterElementImpl2(
      firstFragment: fragment,
      name3: name3,
    );
  }
}

extension TypeParameterElementImpl2Extension on TypeParameterElementImpl2 {
  TypeParameterElementImpl get asElement {
    return firstFragment;
  }
}

extension TypeParameterElementImplExtension on TypeParameterElementImpl {
  TypeParameterElementImpl2 get asElement2 {
    return element;
  }
}
