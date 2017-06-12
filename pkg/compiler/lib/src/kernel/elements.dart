// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Entity model for elements derived from Kernel IR.

import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';

class KLibrary implements LibraryEntity {
  /// Library index used for fast lookup in [KernelWorldBuilder].
  final int libraryIndex;
  final String name;
  final Uri canonicalUri;

  KLibrary(this.libraryIndex, this.name, this.canonicalUri);

  String toString() => 'library($name)';
}

class KClass implements ClassEntity {
  final KLibrary library;

  /// Class index used for fast lookup in [KernelWorldBuilder].
  final int classIndex;

  final String name;
  final bool isAbstract;

  KClass(this.library, this.classIndex, this.name, {this.isAbstract});

  @override
  bool get isClosure => false;

  String toString() => 'class($name)';
}

abstract class KMember implements MemberEntity {
  /// Member index used for fast lookup in [KernelWorldBuilder].
  final int memberIndex;
  final KLibrary library;
  final KClass enclosingClass;
  final Name _name;
  final bool _isStatic;

  KMember(this.memberIndex, this.library, this.enclosingClass, this._name,
      {bool isStatic: false})
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

  String toString() =>
      '$_kind(${enclosingClass != null ? '${enclosingClass.name}.' : ''}$name)';
}

abstract class KFunction extends KMember implements FunctionEntity {
  final ParameterStructure parameterStructure;
  final bool isExternal;
  final AsyncMarker asyncMarker;

  KFunction(int memberIndex, KLibrary library, KClass enclosingClass, Name name,
      this.parameterStructure, this.asyncMarker,
      {bool isStatic: false, this.isExternal: false})
      : super(memberIndex, library, enclosingClass, name, isStatic: isStatic);
}

abstract class KConstructor extends KFunction implements ConstructorEntity {
  final bool isConst;

  KConstructor(int memberIndex, KClass enclosingClass, Name name,
      ParameterStructure parameterStructure, {bool isExternal, this.isConst})
      : super(memberIndex, enclosingClass.library, enclosingClass, name,
            parameterStructure, AsyncMarker.SYNC,
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

class KGenerativeConstructor extends KConstructor {
  KGenerativeConstructor(int constructorIndex, KClass enclosingClass, Name name,
      ParameterStructure parameterStructure, {bool isExternal, bool isConst})
      : super(constructorIndex, enclosingClass, name, parameterStructure,
            isExternal: isExternal, isConst: isConst);

  @override
  bool get isFactoryConstructor => false;

  @override
  bool get isGenerativeConstructor => true;
}

class KFactoryConstructor extends KConstructor {
  @override
  final bool isFromEnvironmentConstructor;

  KFactoryConstructor(int memberIndex, KClass enclosingClass, Name name,
      ParameterStructure parameterStructure,
      {bool isExternal, bool isConst, this.isFromEnvironmentConstructor})
      : super(memberIndex, enclosingClass, name, parameterStructure,
            isExternal: isExternal, isConst: isConst);

  @override
  bool get isFactoryConstructor => true;

  @override
  bool get isGenerativeConstructor => false;
}

class KMethod extends KFunction {
  final bool isAbstract;

  KMethod(int memberIndex, KLibrary library, KClass enclosingClass, Name name,
      ParameterStructure parameterStructure, AsyncMarker asyncMarker,
      {bool isStatic, bool isExternal, this.isAbstract})
      : super(memberIndex, library, enclosingClass, name, parameterStructure,
            asyncMarker,
            isStatic: isStatic, isExternal: isExternal);

  @override
  bool get isFunction => true;

  String get _kind => 'method';
}

class KGetter extends KFunction {
  final bool isAbstract;

  KGetter(int memberIndex, KLibrary library, KClass enclosingClass, Name name,
      AsyncMarker asyncMarker,
      {bool isStatic, bool isExternal, this.isAbstract})
      : super(memberIndex, library, enclosingClass, name,
            const ParameterStructure.getter(), asyncMarker,
            isStatic: isStatic, isExternal: isExternal);

  @override
  bool get isGetter => true;

  String get _kind => 'getter';
}

class KSetter extends KFunction {
  final bool isAbstract;

  KSetter(int memberIndex, KLibrary library, KClass enclosingClass, Name name,
      {bool isStatic, bool isExternal, this.isAbstract})
      : super(memberIndex, library, enclosingClass, name,
            const ParameterStructure.setter(), AsyncMarker.SYNC,
            isStatic: isStatic, isExternal: isExternal);

  @override
  bool get isAssignable => true;

  @override
  bool get isSetter => true;

  String get _kind => 'setter';
}

class KField extends KMember implements FieldEntity {
  final bool isAssignable;
  final bool isConst;

  KField(int memberIndex, KLibrary library, KClass enclosingClass, Name name,
      {bool isStatic, this.isAssignable, this.isConst})
      : super(memberIndex, library, enclosingClass, name, isStatic: isStatic);

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
  final FunctionType functionType;

  KLocalFunction(
      this.name, this.memberContext, this.executableContext, this.functionType);

  String toString() =>
      'local_function(${memberContext.name}.${name ?? '<anonymous>'})';
}
