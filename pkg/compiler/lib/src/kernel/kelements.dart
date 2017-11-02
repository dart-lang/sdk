// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Entity model for elements derived from Kernel IR.

import 'package:kernel/ast.dart' as ir;
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import 'indexed.dart';

const String kElementPrefix = 'k:';

class KLibrary extends IndexedLibrary {
  final String name;
  final Uri canonicalUri;

  KLibrary(this.name, this.canonicalUri);

  String toString() => '${kElementPrefix}library($name)';
}

class KClass extends IndexedClass {
  final KLibrary library;

  final String name;
  final bool isAbstract;

  KClass(this.library, this.name, {this.isAbstract});

  @override
  bool get isClosure => false;

  String toString() => '${kElementPrefix}class($name)';
}

class KTypedef extends IndexedTypedef {
  final KLibrary library;

  final String name;

  KTypedef(this.library, this.name);

  String toString() => '${kElementPrefix}typedef($name)';
}

abstract class KMember extends IndexedMember {
  final KLibrary library;
  final KClass enclosingClass;
  final Name _name;
  final bool _isStatic;

  KMember(this.library, this.enclosingClass, this._name, {bool isStatic: false})
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

  String toString() => '${kElementPrefix}$_kind'
      '(${enclosingClass != null ? '${enclosingClass.name}.' : ''}$name)';
}

abstract class KFunction extends KMember
    implements FunctionEntity, IndexedFunction {
  final ParameterStructure parameterStructure;
  final bool isExternal;
  final AsyncMarker asyncMarker;

  KFunction(KLibrary library, KClass enclosingClass, Name name,
      this.parameterStructure, this.asyncMarker,
      {bool isStatic: false, this.isExternal: false})
      : super(library, enclosingClass, name, isStatic: isStatic);
}

abstract class KConstructor extends KFunction
    implements ConstructorEntity, IndexedConstructor {
  final bool isConst;

  KConstructor(
      KClass enclosingClass, Name name, ParameterStructure parameterStructure,
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

class KGenerativeConstructor extends KConstructor {
  KGenerativeConstructor(
      KClass enclosingClass, Name name, ParameterStructure parameterStructure,
      {bool isExternal, bool isConst})
      : super(enclosingClass, name, parameterStructure,
            isExternal: isExternal, isConst: isConst);

  @override
  bool get isFactoryConstructor => false;

  @override
  bool get isGenerativeConstructor => true;
}

class KFactoryConstructor extends KConstructor {
  @override
  final bool isFromEnvironmentConstructor;

  KFactoryConstructor(
      KClass enclosingClass, Name name, ParameterStructure parameterStructure,
      {bool isExternal, bool isConst, this.isFromEnvironmentConstructor})
      : super(enclosingClass, name, parameterStructure,
            isExternal: isExternal, isConst: isConst);

  @override
  bool get isFactoryConstructor => true;

  @override
  bool get isGenerativeConstructor => false;
}

class KConstructorBody extends KFunction implements ConstructorBodyEntity {
  final ConstructorEntity constructor;

  KConstructorBody(this.constructor)
      : super(
            constructor.library,
            constructor.enclosingClass,
            constructor.memberName,
            constructor.parameterStructure,
            AsyncMarker.SYNC,
            isStatic: false,
            isExternal: false);

  @override
  bool get isFunction => true;

  String get _kind => 'constructor_body';
}

class KMethod extends KFunction {
  final bool isAbstract;

  KMethod(KLibrary library, KClass enclosingClass, Name name,
      ParameterStructure parameterStructure, AsyncMarker asyncMarker,
      {bool isStatic, bool isExternal, this.isAbstract})
      : super(library, enclosingClass, name, parameterStructure, asyncMarker,
            isStatic: isStatic, isExternal: isExternal);

  @override
  bool get isFunction => true;

  String get _kind => 'method';
}

class KGetter extends KFunction {
  final bool isAbstract;

  KGetter(KLibrary library, KClass enclosingClass, Name name,
      AsyncMarker asyncMarker,
      {bool isStatic, bool isExternal, this.isAbstract})
      : super(library, enclosingClass, name, const ParameterStructure.getter(),
            asyncMarker,
            isStatic: isStatic, isExternal: isExternal);

  @override
  bool get isGetter => true;

  String get _kind => 'getter';
}

class KSetter extends KFunction {
  final bool isAbstract;

  KSetter(KLibrary library, KClass enclosingClass, Name name,
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

class KField extends KMember implements FieldEntity, IndexedField {
  final bool isAssignable;
  final bool isConst;

  KField(KLibrary library, KClass enclosingClass, Name name,
      {bool isStatic, this.isAssignable, this.isConst})
      : super(library, enclosingClass, name, isStatic: isStatic);

  @override
  bool get isField => true;

  String get _kind => 'field';
}

class KTypeVariable extends IndexedTypeVariable {
  final Entity typeDeclaration;
  final String name;
  final int index;

  KTypeVariable(this.typeDeclaration, this.name, this.index);

  String toString() =>
      '${kElementPrefix}type_variable(${typeDeclaration.name}.$name)';
}

class KLocalFunction implements Local {
  final String name;
  final MemberEntity memberContext;
  final Entity executableContext;
  final FunctionType functionType;
  final ir.Node node;

  KLocalFunction(this.name, this.memberContext, this.executableContext,
      this.functionType, this.node);

  String toString() => '${kElementPrefix}local_function'
      '(${memberContext.name}.${name ?? '<anonymous>'})';
}
