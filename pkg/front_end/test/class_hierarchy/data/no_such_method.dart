// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Interface:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class Interface {
  /*member: Interface.method#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void method();

  /*member: Interface.getter#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  int get getter;

  /*member: Interface.setter=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void set setter(int value);

  /*member: Interface.field#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  /*member: Interface.field=#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  int field;

  /*member: Interface.finalField#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  final int finalField;
}

/*class: SuperAbstract:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class SuperAbstract {
  /*member: SuperAbstract.noSuchMethod#int:
   classBuilder=SuperAbstract,
   declarations=[
    Object.noSuchMethod,
    SuperAbstract.noSuchMethod],
   declared-overrides=[Object.noSuchMethod],
   isSynthesized
  */
  noSuchMethod(Invocation invocation);
}

/*class: FromSuperAbstract:
 abstractMembers=[
  Interface.field,
  Interface.field=,
  Interface.finalField,
  Interface.getter,
  Interface.method,
  Interface.setter=],
 interfaces=[Interface],
 maxInheritancePath=2,
 superclasses=[
  Object,
  SuperAbstract]
*/
class FromSuperAbstract extends SuperAbstract implements Interface {
  /*member: FromSuperAbstract.noSuchMethod#int:
   classBuilder=FromSuperAbstract,
   declarations=[
    Object.noSuchMethod,
    SuperAbstract.noSuchMethod],
   isSynthesized,
   member=SuperAbstract.noSuchMethod
  */

  /*member: FromSuperAbstract.field#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  /*member: FromSuperAbstract.field=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: FromSuperAbstract.finalField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: FromSuperAbstract.method#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: FromSuperAbstract.getter#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: FromSuperAbstract.setter=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
}

/*class: SuperConcrete:
 hasNoSuchMethod,
 maxInheritancePath=1,
 superclasses=[Object]
*/
class SuperConcrete {
  /*member: SuperConcrete.noSuchMethod#cls:
   classBuilder=SuperConcrete,
   declared-overrides=[Object.noSuchMethod],
   isSourceDeclaration
  */
  @override
  noSuchMethod(Invocation invocation) {
    return null;
  }
}

/*class: FromSuperConcrete:
 hasNoSuchMethod,
 interfaces=[Interface],
 maxInheritancePath=2,
 superclasses=[
  Object,
  SuperConcrete]
*/
class FromSuperConcrete extends SuperConcrete implements Interface {
  /*member: FromSuperConcrete.noSuchMethod#cls:
   classBuilder=FromSuperConcrete,
   inherited-implements=[FromSuperConcrete.noSuchMethod],
   isSynthesized,
   member=SuperConcrete.noSuchMethod
  */
  /*member: FromSuperConcrete.noSuchMethod#int:
   classBuilder=FromSuperConcrete,
   declarations=[
    Object.noSuchMethod,
    SuperConcrete.noSuchMethod],
   isSynthesized,
   member=SuperConcrete.noSuchMethod
  */
  /*member: FromSuperConcrete.method#cls:
   classBuilder=FromSuperConcrete,
   declarations=[Interface.method],
   isSynthesized
  */
  /*member: FromSuperConcrete.getter#cls:
   classBuilder=FromSuperConcrete,
   declarations=[Interface.getter],
   isSynthesized
  */
  /*member: FromSuperConcrete.field#cls:
   classBuilder=FromSuperConcrete,
   declarations=[Interface.field],
   isSynthesized
  */
  /*member: FromSuperConcrete.finalField#cls:
   classBuilder=FromSuperConcrete,
   declarations=[Interface.finalField],
   isSynthesized
  */
  /*member: FromSuperConcrete.field=#cls:
   classBuilder=FromSuperConcrete,
   declarations=[Interface.field=],
   isSynthesized
  */
  /*member: FromSuperConcrete.setter=#cls:
   classBuilder=FromSuperConcrete,
   declarations=[Interface.setter=],
   isSynthesized
  */
}

/*class: FromSuperConcreteAbstract:
 hasNoSuchMethod,
 interfaces=[
  Interface,
  SuperAbstract],
 maxInheritancePath=2,
 superclasses=[
  Object,
  SuperConcrete]
*/
class FromSuperConcreteAbstract extends SuperConcrete
    implements SuperAbstract, Interface {
  /*member: FromSuperConcreteAbstract.noSuchMethod#cls:
   classBuilder=FromSuperConcreteAbstract,
   inherited-implements=[FromSuperConcreteAbstract.noSuchMethod],
   isSynthesized,
   member=SuperConcrete.noSuchMethod
  */
  /*member: FromSuperConcreteAbstract.noSuchMethod#int:
   classBuilder=FromSuperConcreteAbstract,
   declarations=[
    Object.noSuchMethod,
    SuperAbstract.noSuchMethod,
    SuperConcrete.noSuchMethod],
   isSynthesized,
   member=SuperConcrete.noSuchMethod
  */
  /*member: FromSuperConcreteAbstract.method#cls:
   classBuilder=FromSuperConcreteAbstract,
   declarations=[Interface.method],
   isSynthesized
  */
  /*member: FromSuperConcreteAbstract.getter#cls:
   classBuilder=FromSuperConcreteAbstract,
   declarations=[Interface.getter],
   isSynthesized
  */
  /*member: FromSuperConcreteAbstract.field#cls:
   classBuilder=FromSuperConcreteAbstract,
   declarations=[Interface.field],
   isSynthesized
  */
  /*member: FromSuperConcreteAbstract.finalField#cls:
   classBuilder=FromSuperConcreteAbstract,
   declarations=[Interface.finalField],
   isSynthesized
  */
  /*member: FromSuperConcreteAbstract.field=#cls:
   classBuilder=FromSuperConcreteAbstract,
   declarations=[Interface.field=],
   isSynthesized
  */
  /*member: FromSuperConcreteAbstract.setter=#cls:
   classBuilder=FromSuperConcreteAbstract,
   declarations=[Interface.setter=],
   isSynthesized
  */
}

/*class: MixinAbstract:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class MixinAbstract {
  /*member: MixinAbstract.noSuchMethod#int:
   classBuilder=MixinAbstract,
   declarations=[
    MixinAbstract.noSuchMethod,
    Object.noSuchMethod],
   declared-overrides=[Object.noSuchMethod],
   isSynthesized
  */
  noSuchMethod(Invocation invocation);
}

/*class: FromMixinAbstract:
 abstractMembers=[
  Interface.field,
  Interface.field=,
  Interface.finalField,
  Interface.getter,
  Interface.method,
  Interface.setter=],
 interfaces=[Interface],
 maxInheritancePath=2,
 superclasses=[
  MixinAbstract,
  Object]
*/
class FromMixinAbstract extends MixinAbstract implements Interface {
  /*member: FromMixinAbstract.noSuchMethod#int:
   classBuilder=FromMixinAbstract,
   declarations=[
    MixinAbstract.noSuchMethod,
    Object.noSuchMethod],
   isSynthesized,
   member=MixinAbstract.noSuchMethod
  */

  /*member: FromMixinAbstract.field#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  /*member: FromMixinAbstract.field=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: FromMixinAbstract.finalField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: FromMixinAbstract.method#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: FromMixinAbstract.getter#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: FromMixinAbstract.setter=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
}

/*class: MixinConcrete:
 hasNoSuchMethod,
 maxInheritancePath=1,
 superclasses=[Object]
*/
class MixinConcrete {
  /*member: MixinConcrete.noSuchMethod#cls:
   classBuilder=MixinConcrete,
   declared-overrides=[Object.noSuchMethod],
   isSourceDeclaration
  */
  @override
  noSuchMethod(Invocation invocation) {
    return null;
  }
}

/*class: _FromMixinConcrete&Object&MixinConcrete:
 hasNoSuchMethod,
 interfaces=[MixinConcrete],
 maxInheritancePath=2,
 superclasses=[Object]
*/

/*member: _FromMixinConcrete&Object&MixinConcrete.noSuchMethod#cls:
 classBuilder=_FromMixinConcrete&Object&MixinConcrete,
 concreteMixinStub,
 isSynthesized,
 stubTarget=MixinConcrete.noSuchMethod
*/
/*member: _FromMixinConcrete&Object&MixinConcrete.noSuchMethod#int:
 classBuilder=_FromMixinConcrete&Object&MixinConcrete,
 concreteMixinStub,
 declarations=[
  MixinConcrete.noSuchMethod,
  Object.noSuchMethod],
 isSynthesized,
 stubTarget=MixinConcrete.noSuchMethod
*/

/*class: FromMixinConcrete:
 hasNoSuchMethod,
 interfaces=[
  Interface,
  MixinConcrete],
 maxInheritancePath=3,
 superclasses=[
  Object,
  _FromMixinConcrete&Object&MixinConcrete]
*/
class FromMixinConcrete with MixinConcrete implements Interface {
  /*member: FromMixinConcrete.noSuchMethod#cls:
   classBuilder=FromMixinConcrete,
   inherited-implements=[FromMixinConcrete.noSuchMethod],
   isSynthesized,
   member=_FromMixinConcrete&Object&MixinConcrete.noSuchMethod
  */
  /*member: FromMixinConcrete.noSuchMethod#int:
   classBuilder=FromMixinConcrete,
   declarations=[
    Object.noSuchMethod,
    _FromMixinConcrete&Object&MixinConcrete.noSuchMethod],
   isSynthesized,
   member=_FromMixinConcrete&Object&MixinConcrete.noSuchMethod
  */
  /*member: FromMixinConcrete.method#cls:
   classBuilder=FromMixinConcrete,
   declarations=[Interface.method],
   isSynthesized
  */
  /*member: FromMixinConcrete.getter#cls:
   classBuilder=FromMixinConcrete,
   declarations=[Interface.getter],
   isSynthesized
  */
  /*member: FromMixinConcrete.field#cls:
   classBuilder=FromMixinConcrete,
   declarations=[Interface.field],
   isSynthesized
  */
  /*member: FromMixinConcrete.finalField#cls:
   classBuilder=FromMixinConcrete,
   declarations=[Interface.finalField],
   isSynthesized
  */
  /*member: FromMixinConcrete.field=#cls:
   classBuilder=FromMixinConcrete,
   declarations=[Interface.field=],
   isSynthesized
  */
  /*member: FromMixinConcrete.setter=#cls:
   classBuilder=FromMixinConcrete,
   declarations=[Interface.setter=],
   isSynthesized
  */
}

/*class: _FromMixinConcreteAbstract&Object&MixinConcrete:
 hasNoSuchMethod,
 interfaces=[MixinConcrete],
 maxInheritancePath=2,
 superclasses=[Object]
*/

/*member: _FromMixinConcreteAbstract&Object&MixinConcrete.noSuchMethod#cls:
 classBuilder=_FromMixinConcreteAbstract&Object&MixinConcrete,
 concreteMixinStub,
 isSynthesized,
 stubTarget=MixinConcrete.noSuchMethod
*/
/*member: _FromMixinConcreteAbstract&Object&MixinConcrete.noSuchMethod#int:
 classBuilder=_FromMixinConcreteAbstract&Object&MixinConcrete,
 concreteMixinStub,
 declarations=[
  MixinConcrete.noSuchMethod,
  Object.noSuchMethod],
 isSynthesized,
 stubTarget=MixinConcrete.noSuchMethod
*/

/*class: _FromMixinConcreteAbstract&Object&MixinConcrete&MixinAbstract:
 hasNoSuchMethod,
 interfaces=[
  MixinAbstract,
  MixinConcrete],
 maxInheritancePath=3,
 superclasses=[
  Object,
  _FromMixinConcreteAbstract&Object&MixinConcrete]
*/

/*member: _FromMixinConcreteAbstract&Object&MixinConcrete&MixinAbstract.noSuchMethod#cls:
 classBuilder=_FromMixinConcreteAbstract&Object&MixinConcrete&MixinAbstract,
 isSynthesized,
 member=_FromMixinConcreteAbstract&Object&MixinConcrete.noSuchMethod
*/
/*member: _FromMixinConcreteAbstract&Object&MixinConcrete&MixinAbstract.noSuchMethod#int:
 abstractMixinStub,
 classBuilder=_FromMixinConcreteAbstract&Object&MixinConcrete&MixinAbstract,
 declarations=[
  MixinAbstract.noSuchMethod,
  MixinAbstract.noSuchMethod,
  _FromMixinConcreteAbstract&Object&MixinConcrete.noSuchMethod],
 isSynthesized,
 mixin-overrides=[
  MixinAbstract.noSuchMethod,
  _FromMixinConcreteAbstract&Object&MixinConcrete.noSuchMethod]
*/

/*class: FromMixinConcreteAbstract:
 hasNoSuchMethod,
 interfaces=[
  Interface,
  MixinAbstract,
  MixinConcrete],
 maxInheritancePath=4,
 superclasses=[
  Object,
  _FromMixinConcreteAbstract&Object&MixinConcrete,
  _FromMixinConcreteAbstract&Object&MixinConcrete&MixinAbstract]
*/
class FromMixinConcreteAbstract
    with MixinConcrete, MixinAbstract
    implements Interface {
  /*member: FromMixinConcreteAbstract.noSuchMethod#cls:
   classBuilder=FromMixinConcreteAbstract,
   inherited-implements=[FromMixinConcreteAbstract.noSuchMethod],
   isSynthesized,
   member=_FromMixinConcreteAbstract&Object&MixinConcrete.noSuchMethod
  */
  /*member: FromMixinConcreteAbstract.noSuchMethod#int:
   classBuilder=FromMixinConcreteAbstract,
   declarations=[
    Object.noSuchMethod,
    _FromMixinConcreteAbstract&Object&MixinConcrete&MixinAbstract.noSuchMethod],
   isSynthesized,
   member=_FromMixinConcreteAbstract&Object&MixinConcrete&MixinAbstract.noSuchMethod
  */
  /*member: FromMixinConcreteAbstract.method#cls:
   classBuilder=FromMixinConcreteAbstract,
   declarations=[Interface.method],
   isSynthesized
  */
  /*member: FromMixinConcreteAbstract.getter#cls:
   classBuilder=FromMixinConcreteAbstract,
   declarations=[Interface.getter],
   isSynthesized
  */
  /*member: FromMixinConcreteAbstract.field#cls:
   classBuilder=FromMixinConcreteAbstract,
   declarations=[Interface.field],
   isSynthesized
  */
  /*member: FromMixinConcreteAbstract.finalField#cls:
   classBuilder=FromMixinConcreteAbstract,
   declarations=[Interface.finalField],
   isSynthesized
  */
  /*member: FromMixinConcreteAbstract.field=#cls:
   classBuilder=FromMixinConcreteAbstract,
   declarations=[Interface.field=],
   isSynthesized
  */
  /*member: FromMixinConcreteAbstract.setter=#cls:
   classBuilder=FromMixinConcreteAbstract,
   declarations=[Interface.setter=],
   isSynthesized
  */
}

/*class: InterfaceAbstract:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class InterfaceAbstract {
  /*member: InterfaceAbstract.noSuchMethod#int:
   classBuilder=InterfaceAbstract,
   declarations=[
    InterfaceAbstract.noSuchMethod,
    Object.noSuchMethod],
   declared-overrides=[Object.noSuchMethod],
   isSynthesized
  */
  noSuchMethod(Invocation invocation);
}

/*class: FromInterfaceAbstract:
 abstractMembers=[
  Interface.field,
  Interface.field=,
  Interface.finalField,
  Interface.getter,
  Interface.method,
  Interface.setter=],
 interfaces=[
  Interface,
  InterfaceAbstract],
 maxInheritancePath=2,
 superclasses=[Object]
*/
class FromInterfaceAbstract implements InterfaceAbstract, Interface {
  /*member: FromInterfaceAbstract.field#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  /*member: FromInterfaceAbstract.field=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: FromInterfaceAbstract.finalField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: FromInterfaceAbstract.method#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: FromInterfaceAbstract.getter#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: FromInterfaceAbstract.setter=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
}

/*class: InterfaceConcrete:
 hasNoSuchMethod,
 maxInheritancePath=1,
 superclasses=[Object]
*/
class InterfaceConcrete {
  /*member: InterfaceConcrete.noSuchMethod#cls:
   classBuilder=InterfaceConcrete,
   declared-overrides=[Object.noSuchMethod],
   isSourceDeclaration
  */
  @override
  noSuchMethod(Invocation invocation) {
    return null;
  }
}

/*class: FromInterfaceConcrete:
 abstractMembers=[
  Interface.field,
  Interface.field=,
  Interface.finalField,
  Interface.getter,
  Interface.method,
  Interface.setter=],
 interfaces=[
  Interface,
  InterfaceConcrete],
 maxInheritancePath=2,
 superclasses=[Object]
*/
class FromInterfaceConcrete implements InterfaceConcrete, Interface {
  /*member: FromInterfaceConcrete.field#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  /*member: FromInterfaceConcrete.field=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: FromInterfaceConcrete.finalField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: FromInterfaceConcrete.method#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: FromInterfaceConcrete.getter#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: FromInterfaceConcrete.setter=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
}

/*class: DeclaredAbstract:
 abstractMembers=[
  Interface.field,
  Interface.field=,
  Interface.finalField,
  Interface.getter,
  Interface.method,
  Interface.setter=],
 interfaces=[Interface],
 maxInheritancePath=2,
 superclasses=[Object]
*/
class DeclaredAbstract implements Interface {
  /*member: DeclaredAbstract.field#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  /*member: DeclaredAbstract.field=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: DeclaredAbstract.finalField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: DeclaredAbstract.method#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: DeclaredAbstract.getter#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: DeclaredAbstract.setter=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: DeclaredAbstract.noSuchMethod#int:
   classBuilder=DeclaredAbstract,
   declarations=[
    DeclaredAbstract.noSuchMethod,
    Object.noSuchMethod],
   declared-overrides=[Object.noSuchMethod],
   isSynthesized
  */
  noSuchMethod(Invocation invocation);
}

/*class: DeclaredConcrete:
 hasNoSuchMethod,
 interfaces=[Interface],
 maxInheritancePath=2,
 superclasses=[Object]
*/
class DeclaredConcrete implements Interface {
  /*member: DeclaredConcrete.noSuchMethod#cls:
   classBuilder=DeclaredConcrete,
   declared-overrides=[Object.noSuchMethod],
   isSourceDeclaration
  */
  @override
  noSuchMethod(Invocation invocation) {
    return null;
  }
  /*member: DeclaredConcrete.method#cls:
   classBuilder=DeclaredConcrete,
   declarations=[Interface.method],
   isSynthesized
  */
  /*member: DeclaredConcrete.getter#cls:
   classBuilder=DeclaredConcrete,
   declarations=[Interface.getter],
   isSynthesized
  */
  /*member: DeclaredConcrete.field#cls:
   classBuilder=DeclaredConcrete,
   declarations=[Interface.field],
   isSynthesized
  */
  /*member: DeclaredConcrete.finalField#cls:
   classBuilder=DeclaredConcrete,
   declarations=[Interface.finalField],
   isSynthesized
  */
  /*member: DeclaredConcrete.field=#cls:
   classBuilder=DeclaredConcrete,
   declarations=[Interface.field=],
   isSynthesized
  */
  /*member: DeclaredConcrete.setter=#cls:
   classBuilder=DeclaredConcrete,
   declarations=[Interface.setter=],
   isSynthesized
  */
}

main() {}
