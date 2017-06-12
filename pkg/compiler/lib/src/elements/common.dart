// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Mixins that implement convenience methods on [Element] subclasses.

library elements.common;

import '../common/names.dart' show Identifiers, Names, Uris;
import '../common_elements.dart' show CommonElements;
import '../util/util.dart' show Link;
import 'entities.dart';
import 'elements.dart';
import 'names.dart';
import 'types.dart';
import 'resolution_types.dart'
    show ResolutionDartType, ResolutionInterfaceType, ResolutionFunctionType;

abstract class ElementCommon implements Element {
  @override
  bool get isLibrary => kind == ElementKind.LIBRARY;

  @override
  bool get isCompilationUnit => kind == ElementKind.COMPILATION_UNIT;

  @override
  bool get isPrefix => kind == ElementKind.PREFIX;

  @override
  bool get isClass => kind == ElementKind.CLASS;

  @override
  bool get isTypeVariable => kind == ElementKind.TYPE_VARIABLE;

  @override
  bool get isTypedef => kind == ElementKind.TYPEDEF;

  @override
  bool get isFunction => kind == ElementKind.FUNCTION;

  @override
  bool get isAccessor => isGetter || isSetter;

  @override
  bool get isGetter => kind == ElementKind.GETTER;

  @override
  bool get isSetter => kind == ElementKind.SETTER;

  @override
  bool get isConstructor => isGenerativeConstructor || isFactoryConstructor;

  @override
  bool get isGenerativeConstructor =>
      kind == ElementKind.GENERATIVE_CONSTRUCTOR;

  @override
  bool get isGenerativeConstructorBody =>
      kind == ElementKind.GENERATIVE_CONSTRUCTOR_BODY;

  bool get isFactoryConstructor => kind == ElementKind.FACTORY_CONSTRUCTOR;

  @override
  bool get isVariable => kind == ElementKind.VARIABLE;

  @override
  bool get isField => kind == ElementKind.FIELD;

  @override
  bool get isAbstractField => kind == ElementKind.ABSTRACT_FIELD;

  @override
  bool get isRegularParameter => kind == ElementKind.PARAMETER;

  @override
  bool get isInitializingFormal => kind == ElementKind.INITIALIZING_FORMAL;

  @override
  bool get isError => kind == ElementKind.ERROR;

  @override
  bool get isAmbiguous => kind == ElementKind.AMBIGUOUS;

  @override
  bool get isMalformed => false;

  @override
  bool get isWarnOnUse => kind == ElementKind.WARN_ON_USE;

  @override
  bool get impliesType => (kind.category & ElementCategory.IMPLIES_TYPE) != 0;

  @override
  bool get isAssignable {
    if (isFinal || isConst) return false;
    if (isFunction || isConstructor) return false;
    return true;
  }

  @override
  Element get declaration => this;

  @override
  Element get implementation => this;

  @override
  bool get isDeclaration => true;

  @override
  bool get isPatched => false;

  @override
  bool get isPatch => false;

  @override
  bool get isImplementation => true;

  @override
  bool get isInjected => !isPatch && implementationLibrary.isPatch;

  @override
  Element get patch {
    throw new UnsupportedError('patch is not supported on $this');
  }

  @override
  Element get origin {
    throw new UnsupportedError('origin is not supported on $this');
  }

  @override
  ClassElement get contextClass {
    ClassElement cls;
    for (Element e = this; e != null; e = e.enclosingElement) {
      if (e.isClass) {
        // Record [e] instead of returning it directly. We need the last class
        // in the chain since the first classes might be closure classes.
        cls = e.declaration;
      }
    }
    return cls;
  }

  @override
  Element get outermostEnclosingMemberOrTopLevel {
    // TODO(lrn): Why is this called "Outermost"?
    // TODO(johnniwinther): Clean up this method: This method does not return
    // the outermost for elements in closure classes, but some call-sites rely
    // on that behavior.
    for (Element e = this; e != null; e = e.enclosingElement) {
      if (e.isClassMember || e.isTopLevel) {
        return e;
      }
    }
    return null;
  }

  Element get enclosingClassOrCompilationUnit {
    for (Element e = this; e != null; e = e.enclosingElement) {
      if (e.isClass || e.isCompilationUnit) return e;
    }
    return null;
  }
}

abstract class LibraryElementCommon implements LibraryElement {
  @override
  bool get isDartCore => canonicalUri == Uris.dart_core;

  @override
  bool get isPlatformLibrary => canonicalUri.scheme == 'dart';

  @override
  bool get isPackageLibrary => canonicalUri.scheme == 'package';

  @override
  bool get isInternalLibrary =>
      isPlatformLibrary && canonicalUri.path.startsWith('_');

  String get name {
    if (hasLibraryName) {
      return libraryName;
    } else {
      // Use the file name as script name.
      String path = canonicalUri.path;
      return path.substring(path.lastIndexOf('/') + 1);
    }
  }
}

abstract class CompilationUnitElementCommon implements CompilationUnitElement {}

abstract class ClassElementCommon implements ClassElement {
  @override
  Link<InterfaceType> get allSupertypes => allSupertypesAndSelf.supertypes;

  @override
  int get hierarchyDepth => allSupertypesAndSelf.maxDepth;

  @override
  ResolutionInterfaceType asInstanceOf(ClassElement cls) {
    if (cls == this) return thisType;
    return allSupertypesAndSelf.asInstanceOf(cls, cls.hierarchyDepth);
  }

  @override
  ConstructorElement lookupConstructor(String name) {
    Element result = localLookup(name);
    return result != null && result.isConstructor ? result : null;
  }

  /**
   * Find the first member in the class chain with the given [memberName].
   *
   * This method is NOT to be used for resolving
   * unqualified sends because it does not implement the scoping
   * rules, where library scope comes before superclass scope.
   *
   * When called on the implementation element both members declared in the
   * origin and the patch class are returned.
   */
  MemberElement lookupByName(Name memberName, {ClassElement stopAt}) {
    return internalLookupByName(memberName,
        isSuperLookup: false, stopAtSuperclass: stopAt);
  }

  MemberElement lookupSuperByName(Name memberName) {
    return internalLookupByName(memberName, isSuperLookup: true);
  }

  MemberElement internalLookupByName(Name memberName,
      {bool isSuperLookup, ClassElement stopAtSuperclass}) {
    String name = memberName.text;
    bool isPrivate = memberName.isPrivate;
    LibraryElement library = memberName.library;
    for (ClassElement current = isSuperLookup ? superclass : this;
        current != null && current != stopAtSuperclass;
        current = current.superclass) {
      Element member = current.lookupLocalMember(name);
      if (member == null && current.isPatched) {
        // Doing lookups on selectors is done after resolution, so it
        // is safe to look in the patch class.
        member = current.patch.lookupLocalMember(name);
      }
      if (member == null) continue;
      // Private members from a different library are not visible.
      if (isPrivate && !identical(library, member.library)) continue;
      // Static members are not inherited.
      if (member.isStatic && !identical(this, current)) continue;
      // If we find an abstract field we have to make sure that it has
      // the getter or setter part we're actually looking
      // for. Otherwise, we continue up the superclass chain.
      if (member.isAbstractField) {
        AbstractFieldElement field = member;
        GetterElement getter = field.getter;
        SetterElement setter = field.setter;
        if (memberName.isSetter) {
          // Abstract members can be defined in a super class.
          if (setter != null && !setter.isAbstract) {
            return setter;
          }
        } else {
          if (getter != null && !getter.isAbstract) {
            return getter;
          }
        }
        // Abstract members can be defined in a super class.
      } else if (!member.isAbstract && !member.isMalformed) {
        return member;
      }
    }
    return null;
  }

  /**
   * Find the first member in the class chain with the given
   * [memberName]. This method is NOT to be used for resolving
   * unqualified sends because it does not implement the scoping
   * rules, where library scope comes before superclass scope.
   */
  @override
  Element lookupMember(String memberName) {
    Element localMember = lookupLocalMember(memberName);
    return localMember == null ? lookupSuperMember(memberName) : localMember;
  }

  @override
  Link<Element> get constructors {
    // TODO(ajohnsen): See if we can avoid this method at some point.
    Link<Element> result = const Link<Element>();
    // TODO(johnniwinther): Should we include injected constructors?
    forEachMember((_, Element member) {
      if (member.isConstructor) result = result.prepend(member);
    });
    return result;
  }

  /**
   * Lookup super members for the class. This will ignore constructors.
   */
  @override
  Element lookupSuperMember(String memberName) {
    return lookupSuperMemberInLibrary(memberName, library);
  }

  /**
   * Lookup super members for the class that is accessible in [library].
   * This will ignore constructors.
   */
  @override
  Element lookupSuperMemberInLibrary(
      String memberName, LibraryElement library) {
    bool isPrivate = Name.isPrivateName(memberName);
    for (ClassElement s = superclass; s != null; s = s.superclass) {
      // Private members from a different library are not visible.
      if (isPrivate && !identical(library, s.library)) continue;
      Element e = s.lookupLocalMember(memberName);
      if (e == null) continue;
      // Static members are not inherited.
      if (e.isStatic) continue;
      return e;
    }
    return null;
  }

  /**
   * Lookup local members in the class. This will ignore constructors.
   */
  @override
  Element lookupLocalMember(String memberName) {
    var result = localLookup(memberName);
    if (result != null && result.isConstructor) return null;
    return result;
  }

  /**
   * Runs through all members of this class.
   *
   * The enclosing class is passed to the callback. This is useful when
   * [includeSuperAndInjectedMembers] is [:true:].
   *
   * When called on an implementation element both the members in the origin
   * and patch class are included.
   */
  // TODO(johnniwinther): Clean up lookup to get rid of the include predicates.
  @override
  void forEachMember(void f(ClassElement enclosingClass, Element member),
      {includeBackendMembers: false, includeSuperAndInjectedMembers: false}) {
    bool includeInjectedMembers = includeSuperAndInjectedMembers || isPatch;
    ClassElement classElement = declaration;
    do {
      // Iterate through the members in textual order, which requires
      // to reverse the data structure [localMembers] we created.
      // Textual order may be important for certain operations, for
      // example when emitting the initializers of fields.
      classElement.forEachLocalMember((e) => f(classElement, e));
      if (includeBackendMembers) {
        classElement.forEachConstructorBody((e) => f(classElement, e));
      }
      if (includeInjectedMembers) {
        if (classElement.isPatched) {
          classElement.patch.forEachLocalMember((e) {
            if (!e.isPatch) f(classElement, e);
          });
        }
      }
      classElement =
          includeSuperAndInjectedMembers ? classElement.superclass : null;
    } while (classElement != null);
  }

  /**
   * Runs through all instance-field members of this class.
   *
   * The enclosing class is passed to the callback. This is useful when
   * [includeSuperAndInjectedMembers] is [:true:].
   *
   * When called on the implementation element both the fields declared in the
   * origin and in the patch are included.
   */
  @override
  void forEachInstanceField(
      void f(ClassElement enclosingClass, FieldElement field),
      {bool includeSuperAndInjectedMembers: false}) {
    // Filters so that [f] is only invoked with instance fields.
    void fieldFilter(ClassElement enclosingClass, Element member) {
      if (member.isInstanceMember && member.kind == ElementKind.FIELD) {
        f(enclosingClass, member);
      }
    }

    forEachMember(fieldFilter,
        includeSuperAndInjectedMembers: includeSuperAndInjectedMembers);
  }

  /// Similar to [forEachInstanceField] but visits static fields.
  @override
  void forEachStaticField(void f(ClassElement enclosingClass, Element field)) {
    // Filters so that [f] is only invoked with static fields.
    void fieldFilter(ClassElement enclosingClass, Element member) {
      if (!member.isInstanceMember && member.kind == ElementKind.FIELD) {
        f(enclosingClass, member);
      }
    }

    forEachMember(fieldFilter);
  }

  /**
   * Returns true if the [fieldMember] shadows another field.  The given
   * [fieldMember] must be a member of this class, i.e. if there is a field of
   * the same name in the superclass chain.
   *
   * This method also works if the [fieldMember] is private.
   */
  @override
  bool hasFieldShadowedBy(FieldElement fieldMember) {
    assert(fieldMember.isField);
    String fieldName = fieldMember.name;
    bool isPrivate = Name.isPrivateName(fieldName);
    LibraryElement memberLibrary = fieldMember.library;
    ClassElement lookupClass = this.superclass;
    while (lookupClass != null) {
      Element foundMember = lookupClass.lookupLocalMember(fieldName);
      if (foundMember != null) {
        if (foundMember.isField) {
          if (!isPrivate || memberLibrary == foundMember.library) {
            // Private fields can only be shadowed by a field declared in the
            // same library.
            return true;
          }
        }
      }
      lookupClass = lookupClass.superclass;
    }
    return false;
  }

  @override
  bool implementsInterface(ClassElement interface) {
    return this != interface &&
        allSupertypesAndSelf.asInstanceOf(
                interface, interface.hierarchyDepth) !=
            null;
  }

  @override
  bool implementsFunction(CommonElements commonElements) {
    return asInstanceOf(commonElements.functionClass) != null ||
        callType != null;
  }

  @override
  bool isSubclassOf(ClassElement cls) {
    // Use [declaration] for both [this] and [cls], because
    // declaration classes hold the superclass hierarchy.
    cls = cls.declaration;
    for (ClassElement s = declaration; s != null; s = s.superclass) {
      if (identical(s, cls)) return true;
    }
    return false;
  }

  ResolutionFunctionType get callType {
    MemberSignature member = lookupInterfaceMember(Names.call);
    return member != null && member.isMethod ? member.type : null;
  }

  @override
  bool get isNamedMixinApplication {
    return isMixinApplication && !isUnnamedMixinApplication;
  }

  // backendMembers are members that have been added by the backend to simplify
  // compilation. They don't have any user-side counter-part.
  List<ConstructorBodyElement> constructorBodies = <ConstructorBodyElement>[];

  bool get hasConstructorBodies => !constructorBodies.isEmpty;

  void addConstructorBody(ConstructorBodyElement member) {
    // TODO(ngeoffray): Deprecate this method.
    assert(member.isGenerativeConstructorBody);
    constructorBodies.add(member);
  }

  /// Lookup a synthetic element created by the backend.
  ConstructorBodyElement lookupConstructorBody(String memberName) {
    for (ConstructorBodyElement element in constructorBodies) {
      if (element.name == memberName) {
        return element;
      }
    }
    return null;
  }

  void forEachConstructorBody(void f(ConstructorBodyElement member)) {
    constructorBodies.forEach(f);
  }
}

abstract class FunctionSignatureCommon implements FunctionSignature {
  ParameterStructure _parameterStructure;

  ResolutionDartType get returnType => type.returnType;

  void forEachRequiredParameter(void function(Element parameter)) {
    requiredParameters.forEach(function);
  }

  void forEachOptionalParameter(void function(Element parameter)) {
    optionalParameters.forEach(function);
  }

  void forEachParameter(void function(Element parameter)) {
    forEachRequiredParameter(function);
    forEachOptionalParameter(function);
  }

  void orderedForEachParameter(void function(Element parameter)) {
    forEachRequiredParameter(function);
    orderedOptionalParameters.forEach(function);
  }

  int get parameterCount => requiredParameterCount + optionalParameterCount;

  /**
   * Check whether a function with this signature can be used instead of a
   * function with signature [signature] without causing a `noSuchMethod`
   * exception/call.
   */
  bool isCompatibleWith(FunctionSignature signature) {
    if (optionalParametersAreNamed) {
      if (!signature.optionalParametersAreNamed) {
        return requiredParameterCount == signature.parameterCount;
      }
      // If both signatures have named parameters, then they must have
      // the same number of required parameters, and the names in
      // [signature] must all be in [:this:].
      if (requiredParameterCount != signature.requiredParameterCount) {
        return false;
      }
      Set<String> names =
          optionalParameters.map((Element element) => element.name).toSet();
      for (Element namedParameter in signature.optionalParameters) {
        if (!names.contains(namedParameter.name)) {
          return false;
        }
      }
    } else {
      if (signature.optionalParametersAreNamed) return false;
      // There must be at least as many arguments as in the other signature, but
      // this signature must not have more required parameters.  Having more
      // optional parameters is not a problem, they simply are never provided
      // by call sites of a call to a method with the other signature.
      int otherTotalCount = signature.parameterCount;
      return requiredParameterCount <= otherTotalCount &&
          parameterCount >= otherTotalCount;
    }
    return true;
  }

  ParameterStructure get parameterStructure {
    if (_parameterStructure == null) {
      int requiredParameters = requiredParameterCount;
      int positionalParameters;
      List<String> namedParameters;
      if (optionalParametersAreNamed) {
        namedParameters = type.namedParameters;
        positionalParameters = requiredParameters;
      } else {
        namedParameters = const <String>[];
        positionalParameters = requiredParameters + optionalParameterCount;
      }
      _parameterStructure = new ParameterStructure(
          requiredParameters, positionalParameters, namedParameters);
    }
    return _parameterStructure;
  }
}

abstract class MixinApplicationElementCommon
    implements MixinApplicationElement {
  Link<ConstructorElement> get constructors {
    throw new UnsupportedError('Unimplemented $this.constructors');
  }

  FunctionElement _lookupLocalConstructor(String name) {
    for (Link<Element> link = constructors; !link.isEmpty; link = link.tail) {
      if (link.head.name == name) return link.head;
    }
    return null;
  }

  @override
  Element localLookup(String name) {
    Element constructor = _lookupLocalConstructor(name);
    if (constructor != null) return constructor;
    if (mixin == null) return null;
    Element mixedInElement = mixin.localLookup(name);
    if (mixedInElement == null) return null;
    return mixedInElement.isInstanceMember ? mixedInElement : null;
  }

  @override
  void forEachLocalMember(void f(Element member)) {
    constructors.forEach(f);
    if (mixin != null)
      mixin.forEachLocalMember((Element mixedInElement) {
        if (mixedInElement.isInstanceMember) f(mixedInElement);
      });
  }
}

abstract class AbstractFieldElementCommon implements AbstractFieldElement {
  @override
  bool get isInstanceMember {
    return isClassMember && !isStatic;
  }

  @override
  bool get isAbstract {
    return getter != null && getter.isAbstract ||
        setter != null && setter.isAbstract;
  }
}

enum _FromEnvironmentState {
  NOT,
  BOOL,
  INT,
  STRING,
}

abstract class ConstructorElementCommon implements ConstructorElement {
  LibraryElement get library;

  _FromEnvironmentState _fromEnvironmentState;

  _FromEnvironmentState get fromEnvironmentState {
    if (_fromEnvironmentState == null) {
      _fromEnvironmentState = _FromEnvironmentState.NOT;
      if (name == Identifiers.fromEnvironment && library.isDartCore) {
        switch (enclosingClass.name) {
          case 'bool':
            _fromEnvironmentState = _FromEnvironmentState.BOOL;
            break;
          case 'int':
            _fromEnvironmentState = _FromEnvironmentState.INT;
            break;
          case 'String':
            _fromEnvironmentState = _FromEnvironmentState.STRING;
            break;
        }
      }
    }
    return _fromEnvironmentState;
  }

  @override
  bool get isFromEnvironmentConstructor {
    return fromEnvironmentState != _FromEnvironmentState.NOT;
  }

  @override
  bool get isIntFromEnvironmentConstructor {
    return fromEnvironmentState == _FromEnvironmentState.INT;
  }

  @override
  bool get isBoolFromEnvironmentConstructor {
    return fromEnvironmentState == _FromEnvironmentState.BOOL;
  }

  @override
  bool get isStringFromEnvironmentConstructor {
    return fromEnvironmentState == _FromEnvironmentState.STRING;
  }
}
