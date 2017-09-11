// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.elements;

import '../common/names.dart' show Names;
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../kernel/indexed.dart';
import 'closure.dart' show KernelClosureClass;

/// Map from 'frontend' to 'backend' elements.
///
/// Frontend elements are what we read in, these typically represents concepts
/// in Dart. Backend elements are what we generate, these may include elements
/// that do not correspond to a Dart concept, such as closure classes.
///
/// Querying for the frontend element for a backend-only element throws an
/// exception.
class JsToFrontendMap {
  LibraryEntity toBackendLibrary(LibraryEntity library) => library;

  ClassEntity toBackendClass(ClassEntity cls) => cls;

  MemberEntity toBackendMember(MemberEntity member) => member;

  DartType toBackendType(DartType type) => type;

  Set<LibraryEntity> toBackendLibrarySet(Iterable<LibraryEntity> set) {
    return set.map(toBackendLibrary).toSet();
  }

  Set<ClassEntity> toBackendClassSet(Iterable<ClassEntity> set) {
    return set.map(toBackendClass).toSet();
  }

  Set<MemberEntity> toBackendMemberSet(Iterable<MemberEntity> set) {
    return set.map(toBackendMember).toSet();
  }

  Set<FunctionEntity> toBackendFunctionSet(Iterable<FunctionEntity> set) {
    Set<FunctionEntity> newSet = new Set<FunctionEntity>();
    for (FunctionEntity element in set) {
      newSet.add(toBackendMember(element));
    }
    return newSet;
  }

  Map<LibraryEntity, V> toBackendLibraryMap<V>(
      Map<LibraryEntity, V> map, V convert(V value)) {
    return convertMap(map, toBackendLibrary, convert);
  }

  Map<ClassEntity, V> toBackendClassMap<V>(
      Map<ClassEntity, V> map, V convert(V value)) {
    return convertMap(map, toBackendClass, convert);
  }

  Map<MemberEntity, V> toBackendMemberMap<V>(
      Map<MemberEntity, V> map, V convert(V value)) {
    return convertMap(map, toBackendMember, convert);
  }
}

E identity<E>(E element) => element;

Map<K, V> convertMap<K, V>(
    Map<K, V> map, K convertKey(K key), V convertValue(V value)) {
  Map<K, V> newMap = <K, V>{};
  map.forEach((K key, V value) {
    newMap[convertKey(key)] = convertValue(value);
  });
  return newMap;
}

abstract class JsToFrontendMapBase extends JsToFrontendMap {
  DartType toBackendType(DartType type) =>
      const TypeConverter().visit(type, _toBackendEntity);

  Entity _toBackendEntity(Entity entity) {
    if (entity is ClassEntity) return toBackendClass(entity);
    assert(entity is TypeVariableEntity);
    return toBackendTypeVariable(entity);
  }

  TypeVariableEntity toBackendTypeVariable(TypeVariableEntity typeVariable);
}

// TODO(johnniwinther): Merge this with [JsKernelToElementMap].
class JsElementCreatorMixin {
  IndexedLibrary createLibrary(String name, Uri canonicalUri) {
    return new JLibrary(name, canonicalUri);
  }

  IndexedClass createClass(LibraryEntity library, String name,
      {bool isAbstract}) {
    return new JClass(library, name, isAbstract: isAbstract);
  }

  IndexedTypedef createTypedef(LibraryEntity library, String name) {
    return new JTypedef(library, name);
  }

  TypeVariableEntity createTypeVariable(
      Entity typeDeclaration, String name, int index) {
    return new JTypeVariable(typeDeclaration, name, index);
  }

  IndexedConstructor createGenerativeConstructor(ClassEntity enclosingClass,
      Name name, ParameterStructure parameterStructure,
      {bool isExternal, bool isConst}) {
    return new JGenerativeConstructor(enclosingClass, name, parameterStructure,
        isExternal: isExternal, isConst: isConst);
  }

  IndexedConstructor createFactoryConstructor(ClassEntity enclosingClass,
      Name name, ParameterStructure parameterStructure,
      {bool isExternal, bool isConst, bool isFromEnvironmentConstructor}) {
    return new JFactoryConstructor(enclosingClass, name, parameterStructure,
        isExternal: isExternal,
        isConst: isConst,
        isFromEnvironmentConstructor: isFromEnvironmentConstructor);
  }

  JConstructorBody createConstructorBody(ConstructorEntity constructor) {
    return new JConstructorBody(constructor);
  }

  IndexedFunction createGetter(LibraryEntity library,
      ClassEntity enclosingClass, Name name, AsyncMarker asyncMarker,
      {bool isStatic, bool isExternal, bool isAbstract}) {
    return new JGetter(library, enclosingClass, name, asyncMarker,
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  IndexedFunction createMethod(
      LibraryEntity library,
      ClassEntity enclosingClass,
      Name name,
      ParameterStructure parameterStructure,
      AsyncMarker asyncMarker,
      {bool isStatic,
      bool isExternal,
      bool isAbstract}) {
    return new JMethod(
        library, enclosingClass, name, parameterStructure, asyncMarker,
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  IndexedFunction createSetter(
      LibraryEntity library, ClassEntity enclosingClass, Name name,
      {bool isStatic, bool isExternal, bool isAbstract}) {
    return new JSetter(library, enclosingClass, name,
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  IndexedField createField(
      LibraryEntity library, ClassEntity enclosingClass, Name name,
      {bool isStatic, bool isAssignable, bool isConst}) {
    return new JField(library, enclosingClass, name,
        isStatic: isStatic, isAssignable: isAssignable, isConst: isConst);
  }

  LibraryEntity convertLibrary(IndexedLibrary library) {
    return createLibrary(library.name, library.canonicalUri);
  }

  ClassEntity convertClass(LibraryEntity library, IndexedClass cls) {
    return createClass(library, cls.name, isAbstract: cls.isAbstract);
  }

  MemberEntity convertMember(
      LibraryEntity library, ClassEntity cls, IndexedMember member) {
    Name memberName = new Name(member.memberName.text, library,
        isSetter: member.memberName.isSetter);
    if (member.isField) {
      IndexedField field = member;
      return createField(library, cls, memberName,
          isStatic: field.isStatic,
          isAssignable: field.isAssignable,
          isConst: field.isConst);
    } else if (member.isConstructor) {
      IndexedConstructor constructor = member;
      if (constructor.isFactoryConstructor) {
        // TODO(redemption): This should be a JFunction.
        return createFactoryConstructor(
            cls, memberName, constructor.parameterStructure,
            isExternal: constructor.isExternal,
            isConst: constructor.isConst,
            isFromEnvironmentConstructor:
                constructor.isFromEnvironmentConstructor);
      } else {
        return createGenerativeConstructor(
            cls, memberName, constructor.parameterStructure,
            isExternal: constructor.isExternal, isConst: constructor.isConst);
      }
    } else if (member.isGetter) {
      IndexedFunction getter = member;
      return createGetter(library, cls, memberName, getter.asyncMarker,
          isStatic: getter.isStatic,
          isExternal: getter.isExternal,
          isAbstract: getter.isAbstract);
    } else if (member.isSetter) {
      IndexedFunction setter = member;
      return createSetter(library, cls, memberName,
          isStatic: setter.isStatic,
          isExternal: setter.isExternal,
          isAbstract: setter.isAbstract);
    } else {
      IndexedFunction function = member;
      return createMethod(library, cls, memberName, function.parameterStructure,
          function.asyncMarker,
          isStatic: function.isStatic,
          isExternal: function.isExternal,
          isAbstract: function.isAbstract);
    }
  }
}

typedef Entity EntityConverter(Entity cls);

class TypeConverter implements DartTypeVisitor<DartType, EntityConverter> {
  const TypeConverter();

  @override
  DartType visit(DartType type, EntityConverter converter) {
    return type.accept(this, converter);
  }

  List<DartType> visitList(List<DartType> types, EntityConverter converter) {
    List<DartType> list = <DartType>[];
    for (DartType type in types) {
      list.add(visit(type, converter));
    }
    return list;
  }

  @override
  DartType visitDynamicType(DynamicType type, EntityConverter converter) {
    return const DynamicType();
  }

  @override
  DartType visitInterfaceType(InterfaceType type, EntityConverter converter) {
    return new InterfaceType(
        converter(type.element), visitList(type.typeArguments, converter));
  }

  @override
  DartType visitTypedefType(TypedefType type, EntityConverter converter) {
    return new TypedefType(
        converter(type.element), visitList(type.typeArguments, converter));
  }

  @override
  DartType visitFunctionType(FunctionType type, EntityConverter converter) {
    return new FunctionType(
        visit(type.returnType, converter),
        visitList(type.parameterTypes, converter),
        visitList(type.optionalParameterTypes, converter),
        type.namedParameters,
        visitList(type.namedParameterTypes, converter));
  }

  @override
  DartType visitTypeVariableType(
      TypeVariableType type, EntityConverter converter) {
    return new TypeVariableType(converter(type.element));
  }

  @override
  DartType visitVoidType(VoidType type, EntityConverter converter) {
    return const VoidType();
  }
}

const String jsElementPrefix = 'j:';

class JLibrary extends IndexedLibrary {
  final String name;
  final Uri canonicalUri;

  JLibrary(this.name, this.canonicalUri);

  String toString() => '${jsElementPrefix}library($name)';
}

class JClass extends IndexedClass {
  final JLibrary library;

  final String name;
  final bool isAbstract;

  JClass(this.library, this.name, {this.isAbstract});

  @override
  bool get isClosure => false;

  String toString() => '${jsElementPrefix}class($name)';
}

class JTypedef extends IndexedTypedef {
  final JLibrary library;

  final String name;

  JTypedef(this.library, this.name);

  String toString() => '${jsElementPrefix}typedef($name)';
}

abstract class JMember extends IndexedMember {
  final JLibrary library;
  final JClass enclosingClass;
  final Name _name;
  final bool _isStatic;

  JMember(this.library, this.enclosingClass, this._name, {bool isStatic: false})
      : _isStatic = isStatic;

  String get name => _name.text;

  Name get memberName => _name;

  @override
  bool get isAssignable => false;

  @override
  bool get isConst => false;

  @override
  bool get isAbstract => false;

  @override
  bool get isSetter => false;

  @override
  bool get isGetter => false;

  @override
  bool get isFunction => false;

  @override
  bool get isField => false;

  @override
  bool get isConstructor => false;

  @override
  bool get isInstanceMember => enclosingClass != null && !_isStatic;

  @override
  bool get isStatic => enclosingClass != null && _isStatic;

  @override
  bool get isTopLevel => enclosingClass == null;

  String get _kind;

  String toString() => '${jsElementPrefix}$_kind'
      '(${enclosingClass != null ? '${enclosingClass.name}.' : ''}$name)';
}

abstract class JFunction extends JMember
    implements FunctionEntity, IndexedFunction {
  final ParameterStructure parameterStructure;
  final bool isExternal;
  final AsyncMarker asyncMarker;

  JFunction(JLibrary library, JClass enclosingClass, Name name,
      this.parameterStructure, this.asyncMarker,
      {bool isStatic: false, this.isExternal: false})
      : super(library, enclosingClass, name, isStatic: isStatic);
}

abstract class JConstructor extends JFunction
    implements ConstructorEntity, IndexedConstructor {
  final bool isConst;

  JConstructor(
      JClass enclosingClass, Name name, ParameterStructure parameterStructure,
      {bool isExternal, this.isConst})
      : super(enclosingClass.library, enclosingClass, name, parameterStructure,
            AsyncMarker.SYNC,
            isExternal: isExternal);

  @override
  bool get isConstructor => true;

  @override
  bool get isInstanceMember => false;

  @override
  bool get isStatic => false;

  @override
  bool get isTopLevel => false;

  @override
  bool get isFromEnvironmentConstructor => false;

  String get _kind => 'constructor';
}

class JGenerativeConstructor extends JConstructor {
  JGenerativeConstructor(
      JClass enclosingClass, Name name, ParameterStructure parameterStructure,
      {bool isExternal, bool isConst})
      : super(enclosingClass, name, parameterStructure,
            isExternal: isExternal, isConst: isConst);

  @override
  bool get isFactoryConstructor => false;

  @override
  bool get isGenerativeConstructor => true;
}

class JFactoryConstructor extends JConstructor {
  @override
  final bool isFromEnvironmentConstructor;

  JFactoryConstructor(
      JClass enclosingClass, Name name, ParameterStructure parameterStructure,
      {bool isExternal, bool isConst, this.isFromEnvironmentConstructor})
      : super(enclosingClass, name, parameterStructure,
            isExternal: isExternal, isConst: isConst);

  @override
  bool get isFactoryConstructor => true;

  @override
  bool get isGenerativeConstructor => false;
}

class JConstructorBody extends JFunction implements ConstructorBodyEntity {
  final ConstructorEntity constructor;

  JConstructorBody(this.constructor)
      : super(
            constructor.library,
            constructor.enclosingClass,
            constructor.memberName,
            constructor.parameterStructure,
            AsyncMarker.SYNC,
            isStatic: false,
            isExternal: false);

  String get _kind => 'constructor_body';
}

class JMethod extends JFunction {
  final bool isAbstract;

  JMethod(JLibrary library, JClass enclosingClass, Name name,
      ParameterStructure parameterStructure, AsyncMarker asyncMarker,
      {bool isStatic, bool isExternal, this.isAbstract})
      : super(library, enclosingClass, name, parameterStructure, asyncMarker,
            isStatic: isStatic, isExternal: isExternal);

  @override
  bool get isFunction => true;

  String get _kind => 'method';
}

class JGetter extends JFunction {
  final bool isAbstract;

  JGetter(JLibrary library, JClass enclosingClass, Name name,
      AsyncMarker asyncMarker,
      {bool isStatic, bool isExternal, this.isAbstract})
      : super(library, enclosingClass, name, const ParameterStructure.getter(),
            asyncMarker,
            isStatic: isStatic, isExternal: isExternal);

  @override
  bool get isGetter => true;

  String get _kind => 'getter';
}

class JSetter extends JFunction {
  final bool isAbstract;

  JSetter(JLibrary library, JClass enclosingClass, Name name,
      {bool isStatic, bool isExternal, this.isAbstract})
      : super(library, enclosingClass, name, const ParameterStructure.setter(),
            AsyncMarker.SYNC,
            isStatic: isStatic, isExternal: isExternal);

  @override
  bool get isAssignable => true;

  @override
  bool get isSetter => true;

  String get _kind => 'setter';
}

class JField extends JMember implements FieldEntity, IndexedField {
  final bool isAssignable;
  final bool isConst;

  JField(JLibrary library, JClass enclosingClass, Name name,
      {bool isStatic, this.isAssignable, this.isConst})
      : super(library, enclosingClass, name, isStatic: isStatic);

  @override
  bool get isField => true;

  String get _kind => 'field';
}

class JClosureCallMethod extends JMethod {
  JClosureCallMethod(KernelClosureClass containingClass,
      ParameterStructure parameterStructure, AsyncMarker asyncMarker)
      : super(
            containingClass.closureClassEntity.library,
            containingClass.closureClassEntity,
            Names.call,
            parameterStructure,
            asyncMarker,
            isStatic: false,
            isExternal: false,
            isAbstract: false);

  String get _kind => 'closure_call';
}

class JTypeVariable extends IndexedTypeVariable {
  final Entity typeDeclaration;
  final String name;
  final int index;

  JTypeVariable(this.typeDeclaration, this.name, this.index);

  String toString() =>
      '${jsElementPrefix}type_variable(${typeDeclaration.name}.$name)';
}
