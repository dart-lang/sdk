// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Entity model for elements derived from Kernel IR.

import '../elements/elements.dart';
import '../elements/entities.dart';

class KLibrary implements LibraryEntity {
  /// Library index used for fast lookup in [KernelWorldBuilder].
  final int libraryIndex;
  final String name;

  KLibrary(this.libraryIndex, this.name);

  String toString() => 'library($name)';
}

class KClass implements ClassEntity {
  final KLibrary library;

  /// Class index used for fast lookup in [KernelWorldBuilder].
  final int classIndex;
  final String name;

  KClass(this.library, this.classIndex, this.name);

  @override
  bool get isClosure => false;

  String toString() => 'class($name)';
}

abstract class KMember implements MemberEntity {
  final KLibrary library;
  final KClass enclosingClass;
  final Name _name;
  final bool _isStatic;

  KMember(this.library, this.enclosingClass, this._name, {bool isStatic: false})
      : _isStatic = isStatic;

  String get name => _name.text;

  @override
  bool get isAssignable => false;

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

  String toString() =>
      '$_kind(${enclosingClass != null ? '${enclosingClass.name}.' : ''}$name)';
}

abstract class KFunction extends KMember implements FunctionEntity {
  final bool isExternal;

  KFunction(KLibrary library, KClass enclosingClass, Name name,
      {bool isStatic: false, this.isExternal: false})
      : super(library, enclosingClass, name, isStatic: isStatic);
}

abstract class KConstructor extends KFunction implements ConstructorEntity {
  /// Constructor index used for fast lookup in [KernelWorldBuilder].
  final int constructorIndex;

  KConstructor(this.constructorIndex, KClass enclosingClass, Name name,
      {bool isExternal})
      : super(enclosingClass.library, enclosingClass, name,
            isExternal: isExternal);

  @override
  bool get isConstructor => true;

  @override
  bool get isInstanceMember => false;

  @override
  bool get isStatic => false;

  @override
  bool get isTopLevel => false;

  String get _kind => 'constructor';
}

class KGenerativeConstructor extends KConstructor {
  KGenerativeConstructor(int constructorIndex, KClass enclosingClass, Name name,
      {bool isExternal})
      : super(constructorIndex, enclosingClass, name, isExternal: isExternal);

  @override
  bool get isFactoryConstructor => false;

  @override
  bool get isGenerativeConstructor => true;
}

class KFactoryConstructor extends KConstructor {
  KFactoryConstructor(int constructorIndex, KClass enclosingClass, Name name,
      {bool isExternal})
      : super(constructorIndex, enclosingClass, name, isExternal: isExternal);

  @override
  bool get isFactoryConstructor => true;

  @override
  bool get isGenerativeConstructor => false;
}

class KMethod extends KFunction {
  KMethod(KLibrary library, KClass enclosingClass, Name name,
      {bool isStatic, bool isExternal})
      : super(library, enclosingClass, name,
            isStatic: isStatic, isExternal: isExternal);

  @override
  bool get isFunction => true;

  String get _kind => 'method';
}

class KGetter extends KFunction {
  KGetter(KLibrary library, KClass enclosingClass, Name name,
      {bool isStatic, bool isExternal})
      : super(library, enclosingClass, name,
            isStatic: isStatic, isExternal: isExternal);

  @override
  bool get isGetter => true;

  String get _kind => 'getter';
}

class KSetter extends KFunction {
  KSetter(KLibrary library, KClass enclosingClass, Name name,
      {bool isStatic, bool isExternal})
      : super(library, enclosingClass, name,
            isStatic: isStatic, isExternal: isExternal);

  @override
  bool get isAssignable => true;

  @override
  bool get isSetter => true;

  String get _kind => 'setter';
}

class KField extends KMember implements FieldEntity {
  /// Field index used for fast lookup in [KernelWorldBuilder].
  final int fieldIndex;
  final bool isAssignable;

  KField(this.fieldIndex, KLibrary library, KClass enclosingClass, Name name,
      {bool isStatic, this.isAssignable})
      : super(library, enclosingClass, name, isStatic: isStatic);

  @override
  bool get isField => true;

  String get _kind => 'field';
}

class KTypeVariable implements TypeVariableEntity {
  final Entity typeDeclaration;
  final String name;
  final int index;

  KTypeVariable(this.typeDeclaration, this.name, this.index);

  String toString() => 'type_variable(${typeDeclaration.name}.$name)';
}

class KLocalFunction implements Local {
  final String name;
  final MemberEntity memberContext;
  final Entity executableContext;

  KLocalFunction(this.name, this.memberContext, this.executableContext);

  String toString() =>
      'local_function(${memberContext.name}.${name ?? '<anonymous>'})';
}
