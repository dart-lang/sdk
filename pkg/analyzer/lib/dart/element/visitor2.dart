// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines element visitors that support useful patterns for visiting the
/// elements in an [element model](element.dart).
///
/// Dart is an evolving language, and the element model must evolved with it.
/// When the element model changes, the visitor interface will sometimes change
/// as well. If it is desirable to get a compilation error when the structure of
/// the element model has been modified, then you should consider implementing
/// the interface [ElementVisitor2] directly. Doing so will ensure that changes
/// that introduce new classes of elements will be flagged. (Of course, not all
/// changes to the element model require the addition of a new class of element,
/// and hence cannot be caught this way.)
///
/// But if automatic detection of these kinds of changes is not necessary then
/// you will probably want to extend one of the classes in this library because
/// doing so will simplify the task of writing your visitor and guard against
/// future changes to the element model. For example, the
/// [RecursiveElementVisitor2] automates the process of visiting all of the
/// descendants of an element.
library;

import 'package:analyzer/dart/element/element.dart';

/// An element visitor that will recursively visit all of the elements in an
/// element model (like instances of the class [RecursiveElementVisitor2]). In
/// addition, when an element of a specific type is visited not only will the
/// visit method for that specific type of element be invoked, but additional
/// methods for the supertypes of that element will also be invoked. For
/// example, using an instance of this class to visit a [MethodElement] will
/// cause the method [visitMethodElement] to be invoked but will also cause the
/// methods [visitExecutableElement] and [visitElement] to be subsequently
/// invoked. This allows visitors to be written that visit all executable
/// elements without needing to override the visit method for each of the
/// specific subclasses of [ExecutableElement].
///
/// Note, however, that unlike many visitors, element visitors visit objects
/// based on the interfaces implemented by those elements. Because interfaces
/// form a graph structure rather than a tree structure the way classes do, and
/// because it is generally undesirable for an object to be visited more than
/// once, this class flattens the interface graph into a pseudo-tree. In
/// particular, this class treats elements as if the element types were
/// structured in the following way:
///
/// <pre>
/// [Element]
///   [ClassElement]
///   [EnumElement]
///   [ExecutableElement]
///     [ConstructorElement]
///     [LocalFunctionElement]
///     [MethodElement]
///     [PropertyAccessorElement]
///       [GetterElement]
///       [SetterElement]
///     [TopLevelFunctionElement]
///   [ExtensionElement]
///   [ExtensionTypeElement]
///   [FormalParameterElement]
///     [FieldFormalParameterElement]
///     [SuperFormalParameterElement]
///   [GenericFunctionTypeElement]
///   [LabelElement]
///   [LibraryElement]
///   [MixinElement]
///   [MultiplyDefinedElement]
///   [PrefixElement]
///   [TypeAliasElement]
///   [TypeParameterElement]
///   [VariableElement]
///     [LocalVariableElement]
///     [PropertyInducingElement]
///       [FieldElement]
///       [TopLevelVariableElement]
/// </pre>
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or explicitly invoke the more general visit method. Failure to
/// do so will cause the visit methods for superclasses of the element to not be
/// invoked and will cause the children of the visited node to not be visited.
///
/// Clients may extend this class.
class GeneralizingElementVisitor2<R> implements ElementVisitor2<R> {
  @override
  R? visitClassElement(ClassElement element) => visitElement(element);

  @override
  R? visitConstructorElement(ConstructorElement element) =>
      visitExecutableElement(element);

  R? visitElement(Element element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitEnumElement(EnumElement element) => visitElement(element);

  R? visitExecutableElement(ExecutableElement element) => visitElement(element);

  @override
  R? visitExtensionElement(ExtensionElement element) => visitElement(element);

  @override
  R? visitExtensionTypeElement(ExtensionTypeElement element) =>
      visitElement(element);

  @override
  R? visitFieldElement(FieldElement element) =>
      visitPropertyInducingElement(element);

  @override
  R? visitFieldFormalParameterElement(FieldFormalParameterElement element) =>
      visitFormalParameterElement(element);

  @override
  R? visitFormalParameterElement(FormalParameterElement element) =>
      visitElement(element);

  @override
  R? visitGenericFunctionTypeElement(GenericFunctionTypeElement element) =>
      visitElement(element);

  @override
  R? visitGetterElement(GetterElement element) =>
      visitPropertyAccessorElement(element);

  @override
  R? visitLabelElement(LabelElement element) {
    return visitElement(element);
  }

  @override
  R? visitLibraryElement(LibraryElement element) => visitElement(element);

  @override
  R? visitLocalFunctionElement(LocalFunctionElement element) {
    return visitExecutableElement(element);
  }

  @override
  R? visitLocalVariableElement(LocalVariableElement element) {
    return visitVariableElement(element);
  }

  @override
  R? visitMethodElement(MethodElement element) =>
      visitExecutableElement(element);

  @override
  R? visitMixinElement(MixinElement element) => visitElement(element);

  @override
  R? visitMultiplyDefinedElement(MultiplyDefinedElement element) =>
      visitElement(element);

  @override
  R? visitPrefixElement(PrefixElement element) {
    return visitElement(element);
  }

  R? visitPropertyAccessorElement(PropertyAccessorElement element) =>
      visitExecutableElement(element);

  R? visitPropertyInducingElement(PropertyInducingElement element) =>
      visitVariableElement(element);

  @override
  R? visitSetterElement(SetterElement element) =>
      visitPropertyAccessorElement(element);

  @override
  R? visitSuperFormalParameterElement(SuperFormalParameterElement element) =>
      visitFormalParameterElement(element);

  @override
  R? visitTopLevelFunctionElement(TopLevelFunctionElement element) =>
      visitExecutableElement(element);

  @override
  R? visitTopLevelVariableElement(TopLevelVariableElement element) =>
      visitPropertyInducingElement(element);

  @override
  R? visitTypeAliasElement(TypeAliasElement element) => visitElement(element);

  @override
  R? visitTypeParameterElement(TypeParameterElement element) =>
      visitElement(element);

  R? visitVariableElement(VariableElement element) => visitElement(element);
}

/// A visitor that will recursively visit all of the element in an element
/// model. For example, using an instance of this class to visit a
/// [LibraryFragment] will also cause all of the types in the fragment to be
/// visited.
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or must explicitly ask the visited element to visit its
/// children. Failure to do so will cause the children of the visited element to
/// not be visited.
///
/// Clients may extend this class.
class RecursiveElementVisitor2<R> implements ElementVisitor2<R> {
  @override
  R? visitClassElement(ClassElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitConstructorElement(ConstructorElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitEnumElement(EnumElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitExtensionElement(ExtensionElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitExtensionTypeElement(ExtensionTypeElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitFieldElement(FieldElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitFieldFormalParameterElement(FieldFormalParameterElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitFormalParameterElement(FormalParameterElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitGenericFunctionTypeElement(GenericFunctionTypeElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitGetterElement(GetterElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitLabelElement(LabelElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitLibraryElement(LibraryElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitLocalFunctionElement(LocalFunctionElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitLocalVariableElement(LocalVariableElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitMethodElement(MethodElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitMixinElement(MixinElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitMultiplyDefinedElement(MultiplyDefinedElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitPrefixElement(PrefixElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitSetterElement(SetterElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitSuperFormalParameterElement(SuperFormalParameterElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitTopLevelFunctionElement(TopLevelFunctionElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitTopLevelVariableElement(TopLevelVariableElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitTypeAliasElement(TypeAliasElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitTypeParameterElement(TypeParameterElement element) {
    element.visitChildren(this);
    return null;
  }
}

/// A visitor that will do nothing when visiting an element. It is intended to
/// be a superclass for classes that use the visitor pattern primarily as a
/// dispatch mechanism (and hence don't need to recursively visit a whole
/// structure) and that only need to visit a small number of element types.
///
/// Clients may extend this class.
class SimpleElementVisitor2<R> implements ElementVisitor2<R> {
  @override
  R? visitClassElement(ClassElement element) => null;

  @override
  R? visitConstructorElement(ConstructorElement element) => null;

  @override
  R? visitEnumElement(EnumElement element) => null;

  @override
  R? visitExtensionElement(ExtensionElement element) => null;

  @override
  R? visitExtensionTypeElement(ExtensionTypeElement element) => null;

  @override
  R? visitFieldElement(FieldElement element) => null;

  @override
  R? visitFieldFormalParameterElement(FieldFormalParameterElement element) =>
      null;

  @override
  R? visitFormalParameterElement(FormalParameterElement element) => null;

  @override
  R? visitGenericFunctionTypeElement(GenericFunctionTypeElement element) =>
      null;

  @override
  R? visitGetterElement(GetterElement element) => null;

  @override
  R? visitLabelElement(LabelElement element) {
    return null;
  }

  @override
  R? visitLibraryElement(LibraryElement element) => null;

  @override
  R? visitLocalFunctionElement(LocalFunctionElement element) {
    return null;
  }

  @override
  R? visitLocalVariableElement(LocalVariableElement element) {
    return null;
  }

  @override
  R? visitMethodElement(MethodElement element) => null;

  @override
  R? visitMixinElement(MixinElement element) => null;

  @override
  R? visitMultiplyDefinedElement(MultiplyDefinedElement element) => null;

  @override
  R? visitPrefixElement(PrefixElement element) {
    return null;
  }

  @override
  R? visitSetterElement(SetterElement element) => null;

  @override
  R? visitSuperFormalParameterElement(SuperFormalParameterElement element) =>
      null;

  @override
  R? visitTopLevelFunctionElement(TopLevelFunctionElement element) => null;

  @override
  R? visitTopLevelVariableElement(TopLevelVariableElement element) => null;

  @override
  R? visitTypeAliasElement(TypeAliasElement element) => null;

  @override
  R? visitTypeParameterElement(TypeParameterElement element) => null;
}

/// An AST visitor that will throw an exception if any of the visit methods that
/// are invoked have not been overridden. It is intended to be a superclass for
/// classes that implement the visitor pattern and need to (a) override all of
/// the visit methods or (b) need to override a subset of the visit method and
/// want to catch when any other visit methods have been invoked.
///
/// Clients may extend this class.
class ThrowingElementVisitor2<R> implements ElementVisitor2<R> {
  @override
  R? visitClassElement(ClassElement element) => _throw(element);

  @override
  R? visitConstructorElement(ConstructorElement element) => _throw(element);

  @override
  R? visitEnumElement(EnumElement element) => _throw(element);

  @override
  R? visitExtensionElement(ExtensionElement element) => _throw(element);

  @override
  R? visitExtensionTypeElement(ExtensionTypeElement element) => _throw(element);

  @override
  R? visitFieldElement(FieldElement element) => _throw(element);

  @override
  R? visitFieldFormalParameterElement(FieldFormalParameterElement element) =>
      _throw(element);

  @override
  R? visitFormalParameterElement(FormalParameterElement element) =>
      _throw(element);

  @override
  R? visitGenericFunctionTypeElement(GenericFunctionTypeElement element) =>
      _throw(element);

  @override
  R? visitGetterElement(GetterElement element) => _throw(element);

  @override
  R? visitLabelElement(LabelElement element) {
    _throw(element);
  }

  @override
  R? visitLibraryElement(LibraryElement element) => _throw(element);

  @override
  R? visitLocalFunctionElement(LocalFunctionElement element) {
    _throw(element);
  }

  @override
  R? visitLocalVariableElement(LocalVariableElement element) {
    _throw(element);
  }

  @override
  R? visitMethodElement(MethodElement element) => _throw(element);

  @override
  R? visitMixinElement(MixinElement element) => _throw(element);

  @override
  R? visitMultiplyDefinedElement(MultiplyDefinedElement element) =>
      _throw(element);

  @override
  R? visitPrefixElement(PrefixElement element) {
    _throw(element);
  }

  @override
  R? visitSetterElement(SetterElement element) => _throw(element);

  @override
  R? visitSuperFormalParameterElement(SuperFormalParameterElement element) =>
      _throw(element);

  @override
  R? visitTopLevelFunctionElement(TopLevelFunctionElement element) =>
      _throw(element);

  @override
  R? visitTopLevelVariableElement(TopLevelVariableElement element) =>
      _throw(element);

  @override
  R? visitTypeAliasElement(TypeAliasElement element) => _throw(element);

  @override
  R? visitTypeParameterElement(TypeParameterElement element) => _throw(element);

  Never _throw(Element element) {
    throw Exception('Missing implementation of visit${element.runtimeType}');
  }
}
