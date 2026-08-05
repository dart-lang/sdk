// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart'
    show DiagnosticMessageImpl;
import 'package:meta/meta.dart';

class MockLibraryImportElement implements Element {
  final LibraryImportImpl import;

  MockLibraryImportElement(LibraryImport import)
    : import = import as LibraryImportImpl;

  @override
  Element get baseElement => this;

  @override
  LibraryElement get enclosingElement => library;

  @override
  ElementKind get kind => ElementKind.IMPORT;

  @override
  LibraryElementImpl get library => libraryFragment.element;

  LibraryFragmentImpl get libraryFragment => import.libraryFragment;

  @override
  String? get name => import.prefix?.name;

  @override
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
}

extension CompilationUnitElementImplExtension on LibraryFragmentImpl {
  /// Returns this library fragment, and all its enclosing fragments.
  List<LibraryFragmentImpl> get withEnclosing {
    var result = <LibraryFragmentImpl>[];
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

extension Element2Extension on Element {
  /// Whether the element is effectively [internal].
  bool get isInternal {
    if (metadata.hasInternal) {
      return true;
    }
    if (this case PropertyAccessorElement accessor) {
      var variable = accessor.variable;
      if (variable.metadata.hasInternal) {
        return true;
      }
    }
    return false;
  }

  /// Whether the element is effectively [protected].
  bool get isProtected {
    var self = this;
    if (self is PropertyAccessorElement &&
        self.enclosingElement is InterfaceElement) {
      if (self.metadata.hasProtected) {
        return true;
      }
      var variable = self.variable;
      if (variable.metadata.hasProtected) {
        return true;
      }
    }
    if (self is MethodElement &&
        self.enclosingElement is InterfaceElement &&
        self.metadata.hasProtected) {
      return true;
    }
    return false;
  }

  /// Whether the element is effectively [visibleForTesting].
  bool get isVisibleForTesting {
    if (metadata.hasVisibleForTesting) {
      return true;
    }
    if (this case PropertyAccessorElement accessor) {
      var variable = accessor.variable;
      if (variable.metadata.hasVisibleForTesting) {
        return true;
      }
    }
    return false;
  }
}

extension ExecutableElement2OrMemberExtension on InternalExecutableElement {
  ExecutableFragmentImpl get declarationImpl => baseElement.firstFragment;
}

extension FormalParameterElementExtension on FormalParameterElement {
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

extension FragmentImplExtension on FragmentImpl {
  DiagnosticMessageImpl? contextMessageAt(String message) {
    var libraryFragment = this.libraryFragment;
    if (libraryFragment == null) {
      return null;
    }

    var (:offset, :length) = switch (this) {
      ConstructorFragmentImpl fragment => (
        offset: fragment.nameOffset ?? fragment.typeNameOffset,
        length: fragment.nameOffset != null
            ? fragment.name.length
            : fragment.typeName?.length,
      ),
      _ => (offset: nameOffset, length: name?.length),
    };
    if (offset == null || length == null) {
      return null;
    }

    return DiagnosticMessageImpl(
      filePath: libraryFragment.source.fullName,
      message: message,
      offset: offset,
      length: length,
      url: null,
    );
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

extension ListOfTypeParameterElement2Extension on List<TypeParameterElement> {
  List<TypeParameterType> instantiateNone() {
    return map((e) {
      return e.instantiate(nullabilitySuffix: NullabilitySuffix.none);
    }).toList();
  }
}

extension PropertyInducingElementExtension on PropertyInducingElement {
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

extension TypeParameterElement2Extension on TypeParameterElement {
  TypeParameterElementImpl freshCopy() {
    var fragment = TypeParameterFragmentImpl(name: name);
    var element = TypeParameterElementImpl(firstFragment: fragment);
    element.bound = bound as TypeImpl?;
    return element;
  }
}
