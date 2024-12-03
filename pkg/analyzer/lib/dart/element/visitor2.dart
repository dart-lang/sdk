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

import 'package:analyzer/dart/element/element2.dart';

/// An element visitor that will recursively visit all of the elements in an
/// element model (like instances of the class [RecursiveElementVisitor2]). In
/// addition, when an element of a specific type is visited not only will the
/// visit method for that specific type of element be invoked, but additional
/// methods for the supertypes of that element will also be invoked. For
/// example, using an instance of this class to visit a [MethodElement2] will
/// cause the method [visitMethodElement] to be invoked but will also cause the
/// methods [visitExecutableElement] and [visitElement] to be subsequently
/// invoked. This allows visitors to be written that visit all executable
/// elements without needing to override the visit method for each of the
/// specific subclasses of [ExecutableElement2].
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
/// [Element2]
///   [ClassElement2]
///   [ExecutableElement2]
///       [ConstructorElement2]
///       [GetterElement]
///       [LocalFunctionElement]
///       [MethodElement2]
///       [SetterElement]
///   [LabelElement2]
///   [LibraryElement2]
///   [MultiplyDefinedElement2]
///   [PrefixElement2]
///   [TypeAliasElement2]
///   [TypeParameterElement2]
///   [VariableElement2]
///       [PropertyInducingElement2]
///           [FieldElement2]
///           [TopLevelVariableElement2]
///       [PromotableElement2]
///           [LocalVariableElement2]
///           [FormalParameterElement]
///               [FieldFormalParameterElement2]
///               [SuperFormalParameterElement2]
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
  R? visitClassElement(ClassElement2 element) => visitElement(element);

  @override
  R? visitConstructorElement(ConstructorElement2 element) =>
      visitExecutableElement(element);

  R? visitElement(Element2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitEnumElement(EnumElement2 element) => visitElement(element);

  R? visitExecutableElement(ExecutableElement2 element) =>
      visitElement(element);

  @override
  R? visitExtensionElement(ExtensionElement2 element) => visitElement(element);

  @override
  R? visitExtensionTypeElement(ExtensionTypeElement2 element) =>
      visitElement(element);

  @override
  R? visitFieldElement(FieldElement2 element) =>
      visitPropertyInducingElement(element);

  @override
  R? visitFieldFormalParameterElement(FieldFormalParameterElement2 element) =>
      visitFormalParameterElement(element);

  @override
  R? visitFormalParameterElement(FormalParameterElement element) =>
      visitElement(element);

  @override
  R? visitGenericFunctionTypeElement(GenericFunctionTypeElement2 element) =>
      visitElement(element);

  @override
  R? visitGetterElement(GetterElement element) =>
      visitPropertyAccessorElement(element);

  @override
  R? visitLabelElement(LabelElement2 element) {
    return visitElement(element);
  }

  @override
  R? visitLibraryElement(LibraryElement2 element) => visitElement(element);

  @override
  R? visitLocalFunctionElement(LocalFunctionElement element) {
    return visitExecutableElement(element);
  }

  @override
  R? visitLocalVariableElement(LocalVariableElement2 element) {
    return visitVariableElement(element);
  }

  @override
  R? visitMethodElement(MethodElement2 element) =>
      visitExecutableElement(element);

  @override
  R? visitMixinElement(MixinElement2 element) => visitElement(element);

  @override
  R? visitMultiplyDefinedElement(MultiplyDefinedElement2 element) =>
      visitElement(element);

  @override
  R? visitPrefixElement(PrefixElement2 element) {
    return visitElement(element);
  }

  R? visitPropertyAccessorElement(PropertyAccessorElement2 element) =>
      visitExecutableElement(element);

  R? visitPropertyInducingElement(PropertyInducingElement2 element) =>
      visitVariableElement(element);

  @override
  R? visitSetterElement(SetterElement element) =>
      visitPropertyAccessorElement(element);

  @override
  R? visitSuperFormalParameterElement(SuperFormalParameterElement2 element) =>
      visitFormalParameterElement(element);

  @override
  R? visitTopLevelFunctionElement(TopLevelFunctionElement element) =>
      visitExecutableElement(element);

  @override
  R? visitTopLevelVariableElement(TopLevelVariableElement2 element) =>
      visitPropertyInducingElement(element);

  @override
  R? visitTypeAliasElement(TypeAliasElement2 element) => visitElement(element);

  @override
  R? visitTypeParameterElement(TypeParameterElement2 element) =>
      visitElement(element);

  R? visitVariableElement(VariableElement2 element) => visitElement(element);
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
  R? visitClassElement(ClassElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitConstructorElement(ConstructorElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitEnumElement(EnumElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitExtensionElement(ExtensionElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitExtensionTypeElement(ExtensionTypeElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitFieldElement(FieldElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitFieldFormalParameterElement(FieldFormalParameterElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitFormalParameterElement(FormalParameterElement element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitGenericFunctionTypeElement(GenericFunctionTypeElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitGetterElement(GetterElement element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitLabelElement(LabelElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitLibraryElement(LibraryElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitLocalFunctionElement(LocalFunctionElement element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitLocalVariableElement(LocalVariableElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitMethodElement(MethodElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitMixinElement(MixinElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitMultiplyDefinedElement(MultiplyDefinedElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitPrefixElement(PrefixElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitSetterElement(SetterElement element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitSuperFormalParameterElement(SuperFormalParameterElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitTopLevelFunctionElement(TopLevelFunctionElement element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitTopLevelVariableElement(TopLevelVariableElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitTypeAliasElement(TypeAliasElement2 element) {
    element.visitChildren2(this);
    return null;
  }

  @override
  R? visitTypeParameterElement(TypeParameterElement2 element) {
    element.visitChildren2(this);
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
  R? visitClassElement(ClassElement2 element) => null;

  @override
  R? visitConstructorElement(ConstructorElement2 element) => null;

  @override
  R? visitEnumElement(EnumElement2 element) => null;

  @override
  R? visitExtensionElement(ExtensionElement2 element) => null;

  @override
  R? visitExtensionTypeElement(ExtensionTypeElement2 element) => null;

  @override
  R? visitFieldElement(FieldElement2 element) => null;

  @override
  R? visitFieldFormalParameterElement(FieldFormalParameterElement2 element) =>
      null;

  @override
  R? visitFormalParameterElement(FormalParameterElement element) => null;

  @override
  R? visitGenericFunctionTypeElement(GenericFunctionTypeElement2 element) =>
      null;

  @override
  R? visitGetterElement(GetterElement element) => null;

  @override
  R? visitLabelElement(LabelElement2 element) {
    return null;
  }

  @override
  R? visitLibraryElement(LibraryElement2 element) => null;

  @override
  R? visitLocalFunctionElement(LocalFunctionElement element) {
    return null;
  }

  @override
  R? visitLocalVariableElement(LocalVariableElement2 element) {
    return null;
  }

  @override
  R? visitMethodElement(MethodElement2 element) => null;

  @override
  R? visitMixinElement(MixinElement2 element) => null;

  @override
  R? visitMultiplyDefinedElement(MultiplyDefinedElement2 element) => null;

  @override
  R? visitPrefixElement(PrefixElement2 element) {
    return null;
  }

  @override
  R? visitSetterElement(SetterElement element) => null;

  @override
  R? visitSuperFormalParameterElement(SuperFormalParameterElement2 element) =>
      null;

  @override
  R? visitTopLevelFunctionElement(TopLevelFunctionElement element) => null;

  @override
  R? visitTopLevelVariableElement(TopLevelVariableElement2 element) => null;

  @override
  R? visitTypeAliasElement(TypeAliasElement2 element) => null;

  @override
  R? visitTypeParameterElement(TypeParameterElement2 element) => null;
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
  R? visitClassElement(ClassElement2 element) => _throw(element);

  @override
  R? visitConstructorElement(ConstructorElement2 element) => _throw(element);

  @override
  R? visitEnumElement(EnumElement2 element) => _throw(element);

  @override
  R? visitExtensionElement(ExtensionElement2 element) => _throw(element);

  @override
  R? visitExtensionTypeElement(ExtensionTypeElement2 element) =>
      _throw(element);

  @override
  R? visitFieldElement(FieldElement2 element) => _throw(element);

  @override
  R? visitFieldFormalParameterElement(FieldFormalParameterElement2 element) =>
      _throw(element);

  @override
  R? visitFormalParameterElement(FormalParameterElement element) =>
      _throw(element);

  @override
  R? visitGenericFunctionTypeElement(GenericFunctionTypeElement2 element) =>
      _throw(element);

  @override
  R? visitGetterElement(GetterElement element) => _throw(element);

  @override
  R? visitLabelElement(LabelElement2 element) {
    _throw(element);
  }

  @override
  R? visitLibraryElement(LibraryElement2 element) => _throw(element);

  @override
  R? visitLocalFunctionElement(LocalFunctionElement element) {
    _throw(element);
  }

  @override
  R? visitLocalVariableElement(LocalVariableElement2 element) {
    _throw(element);
  }

  @override
  R? visitMethodElement(MethodElement2 element) => _throw(element);

  @override
  R? visitMixinElement(MixinElement2 element) => _throw(element);

  @override
  R? visitMultiplyDefinedElement(MultiplyDefinedElement2 element) =>
      _throw(element);

  @override
  R? visitPrefixElement(PrefixElement2 element) {
    _throw(element);
  }

  @override
  R? visitSetterElement(SetterElement element) => _throw(element);

  @override
  R? visitSuperFormalParameterElement(SuperFormalParameterElement2 element) =>
      _throw(element);

  @override
  R? visitTopLevelFunctionElement(TopLevelFunctionElement element) =>
      _throw(element);

  @override
  R? visitTopLevelVariableElement(TopLevelVariableElement2 element) =>
      _throw(element);

  @override
  R? visitTypeAliasElement(TypeAliasElement2 element) => _throw(element);

  @override
  R? visitTypeParameterElement(TypeParameterElement2 element) =>
      _throw(element);

  Never _throw(Element2 element) {
    throw Exception('Missing implementation of visit${element.runtimeType}');
  }
}
