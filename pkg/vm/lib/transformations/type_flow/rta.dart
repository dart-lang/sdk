// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Rapid type analysis on kernel AST.
library;

import 'dart:core' hide Type;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/target/targets.dart' show Target;

import 'calls.dart' as calls
    show Selector, DirectSelector, InterfaceSelector, VirtualSelector;
import 'native_code.dart'
    show EntryPointsListener, NativeCodeOracle, PragmaEntryPointsVisitor;
import 'protobuf_handler.dart' show ProtobufHandler;
import 'types.dart' show TFClass, Type, ConcreteType, RecordShape;
import 'utils.dart' show combineHashes;
import '../pragma.dart' show ConstantPragmaAnnotationParser;

class Selector {
  final Name name;
  final bool setter;

  Selector(this.name, this.setter);

  @override
  int get hashCode => combineHashes(name.hashCode, setter.hashCode);

  @override
  bool operator ==(Object other) =>
      other is Selector &&
      this.name == other.name &&
      this.setter == other.setter;
}

class ClassInfo extends TFClass {
  final ClassInfo? superclass;
  final Set<ClassInfo> supertypes; // All super-types including this.
  final Set<ClassInfo> subclasses = Set<ClassInfo>();
  final Set<ClassInfo> subtypes = Set<ClassInfo>();

  final Set<Selector>
      calledDynamicSelectors; // Selectors called with dynamic and interface calls.
  final Set<Selector> calledVirtualSelectors;

  bool isAllocated = false;

  late final Map<Name, Member> _dispatchTargetsSetters =
      _initDispatchTargets(true);
  late final Map<Name, Member> _dispatchTargetsNonSetters =
      _initDispatchTargets(false);

  ClassInfo(int id, Class classNode, this.superclass, this.supertypes,
      this.calledDynamicSelectors, this.calledVirtualSelectors)
      : super(id, classNode, null) {
    supertypes.add(this);
    for (var sup in supertypes) {
      sup.subtypes.add(this);
    }
    for (ClassInfo? sup = this; sup != null; sup = sup.superclass) {
      sup.subclasses.add(this);
    }
  }

  Map<Name, Member> _initDispatchTargets(bool setters) {
    Map<Name, Member> targets;
    final superclass = this.superclass;
    if (superclass != null) {
      targets = Map.from(setters
          ? superclass._dispatchTargetsSetters
          : superclass._dispatchTargetsNonSetters);
    } else {
      targets = {};
    }
    for (Field f in classNode.fields) {
      if (!f.isStatic && !f.isAbstract) {
        if (!setters || f.hasSetter) {
          targets[f.name] = f;
        }
      }
    }
    for (Procedure p in classNode.procedures) {
      if (!p.isStatic && !p.isAbstract) {
        if (p.isSetter == setters) {
          targets[p.name] = p;
        }
      }
    }
    return targets;
  }

  Member? getDispatchTarget(Selector selector) {
    return (selector.setter
        ? _dispatchTargetsSetters
        : _dispatchTargetsNonSetters)[selector.name];
  }
}

class _ClassHierarchyCache {
  final Map<Class, ClassInfo> classes = <Class, ClassInfo>{};
  int _classIdCounter = 0;

  _ClassHierarchyCache();

  ClassInfo getClassInfo(Class c) {
    return classes[c] ??= _createClassInfo(c);
  }

  ClassInfo _createClassInfo(Class c) {
    final supertypes = Set<ClassInfo>();
    final dynSel = Set<Selector>();
    for (var sup in c.supers) {
      final supInfo = getClassInfo(sup.classNode);
      supertypes.addAll(supInfo.supertypes);
      dynSel.addAll(supInfo.calledDynamicSelectors);
    }
    Class? superclassNode = c.superclass;
    ClassInfo? superclass;
    final virtSel = Set<Selector>();
    if (superclassNode != null) {
      superclass = getClassInfo(superclassNode);
      virtSel.addAll(superclass.calledVirtualSelectors);
    }
    return ClassInfo(
        ++_classIdCounter, c, superclass, supertypes, dynSel, virtSel);
  }

  ConcreteType addAllocatedClass(Class cl, RapidTypeAnalysis rta) {
    assert(!cl.isAbstract);
    final ClassInfo classInfo = getClassInfo(cl);
    if (!classInfo.isAllocated) {
      classInfo.isAllocated = true;
      for (var sel in classInfo.calledDynamicSelectors) {
        final member = classInfo.getDispatchTarget(sel);
        if (member != null) {
          rta.addMember(member);
        }
      }
      for (var sel in classInfo.calledVirtualSelectors) {
        final member = classInfo.getDispatchTarget(sel);
        if (member != null) {
          rta.addMember(member);
        }
      }
    }
    return classInfo.concreteType;
  }

  void addDynamicCall(Selector selector, Class cl, RapidTypeAnalysis rta) {
    final ClassInfo classInfo = getClassInfo(cl);
    for (var sub in classInfo.subtypes) {
      if (sub.calledDynamicSelectors.add(selector) && sub.isAllocated) {
        final member = sub.getDispatchTarget(selector);
        if (member != null) {
          rta.addMember(member);
        }
      }
    }
  }

  void addVirtualCall(Selector selector, Class cl, RapidTypeAnalysis rta) {
    final ClassInfo classInfo = getClassInfo(cl);
    for (var sub in classInfo.subclasses) {
      if (sub.calledVirtualSelectors.add(selector) && sub.isAllocated) {
        final member = sub.getDispatchTarget(selector);
        if (member != null) {
          rta.addMember(member);
        }
      }
    }
  }
}

class RapidTypeAnalysis {
  final CoreTypes coreTypes;
  final ClassHierarchy hierarchy;
  final _ClassHierarchyCache hierarchyCache = _ClassHierarchyCache();
  final ProtobufHandler? protobufHandler;

  final Set<Member> visited = {};
  final List<Member> workList = [];

  RapidTypeAnalysis(Component component, this.coreTypes, Target target,
      this.hierarchy, LibraryIndex libraryIndex, this.protobufHandler) {
    Procedure? main = component.mainMethod;
    if (main != null) {
      addMember(main);
    }
    final annotationMatcher = ConstantPragmaAnnotationParser(coreTypes, target);
    final nativeCodeOracle = NativeCodeOracle(libraryIndex, annotationMatcher);
    component.accept(PragmaEntryPointsVisitor(
        _EntryPointsListenerImpl(this), nativeCodeOracle, annotationMatcher));
    run();
  }

  List<Class> get allocatedClasses {
    return <Class>[
      for (var entry in hierarchyCache.classes.entries)
        if (entry.value.isAllocated) entry.key
    ];
  }

  bool isAllocatedClass(Class cl) =>
      hierarchyCache.classes[cl]?.isAllocated ?? false;

  ConcreteType addAllocatedClass(Class cl) =>
      hierarchyCache.addAllocatedClass(cl, this);

  void addMember(Member member) {
    if (visited.add(member)) {
      workList.add(member);
    }
  }

  void addCall(Class? currentClass, Member? interfaceTarget, Name name,
      bool isVirtual, bool isSetter) {
    final Class cl = isVirtual
        ? currentClass!
        : (interfaceTarget != null
            ? interfaceTarget.enclosingClass!
            : coreTypes.objectClass);
    final Selector selector = Selector(name, isSetter);
    if (isVirtual) {
      hierarchyCache.addVirtualCall(selector, cl, this);
    } else {
      hierarchyCache.addDynamicCall(selector, cl, this);
    }
  }

  void run() {
    final memberVisitor = _MemberVisitor(this);
    while (workList.isNotEmpty || invalidateProtobufFields()) {
      final member = workList.removeLast();
      protobufHandler?.beforeSummaryCreation(member);
      member.accept(memberVisitor);
    }
  }

  bool invalidateProtobufFields() {
    final protobufHandler = this.protobufHandler;
    if (protobufHandler == null) {
      return false;
    }
    final fields = protobufHandler.getInvalidatedFields();
    if (fields.isEmpty) {
      return false;
    }
    // Protobuf handler replaced contents of static field initializers.
    bool invalidated = false;
    for (var field in fields) {
      assert(field.isStatic);
      if (visited.contains(field)) {
        workList.add(field);
        invalidated = true;
      }
    }
    return invalidated;
  }
}

class _MemberVisitor extends RecursiveVisitor {
  final RapidTypeAnalysis rta;
  final _ConstantVisitor _constantVisitor;

  Class? _currentClass;
  ClassInfo? _superclassInfo;

  _MemberVisitor(this.rta) : _constantVisitor = _ConstantVisitor(rta);

  ClassInfo get superclassInfo => _superclassInfo ??=
      rta.hierarchyCache.getClassInfo(_currentClass!.superclass!);

  @override
  void defaultMember(Member node) {
    _superclassInfo = null;
    _currentClass = node.enclosingClass;
    node.visitChildren(this);
    if (node is Constructor) {
      // Make sure instance field initializers are visited.
      for (var f in _currentClass!.members) {
        if (f is Field && !f.isStatic) {
          f.initializer?.accept(this);
        }
      }
    }
    _superclassInfo = null;
    _currentClass = null;
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    rta.addAllocatedClass(node.constructedType.classNode);
    rta.addMember(node.target);
    node.visitChildren(this);
  }

  @override
  void visitInstanceInvocation(InstanceInvocation node) {
    rta.addCall(_currentClass, node.interfaceTarget, node.name,
        node.receiver is ThisExpression, false);
    node.visitChildren(this);
  }

  @override
  void visitDynamicInvocation(DynamicInvocation node) {
    rta.addCall(null, null, node.name, false, false);
    node.visitChildren(this);
  }

  @override
  void visitEqualsCall(EqualsCall node) {
    rta.addCall(_currentClass, node.interfaceTarget, node.interfaceTarget.name,
        node.left is ThisExpression, false);
    node.visitChildren(this);
  }

  @override
  void visitInstanceGet(InstanceGet node) {
    rta.addCall(_currentClass, node.interfaceTarget, node.name,
        node.receiver is ThisExpression, false);
    node.visitChildren(this);
  }

  @override
  void visitInstanceTearOff(InstanceTearOff node) {
    rta.addCall(_currentClass, node.interfaceTarget, node.name,
        node.receiver is ThisExpression, false);
    node.visitChildren(this);
  }

  @override
  void visitDynamicGet(DynamicGet node) {
    rta.addCall(null, null, node.name, false, false);
    node.visitChildren(this);
  }

  @override
  void visitInstanceSet(InstanceSet node) {
    rta.addCall(_currentClass, node.interfaceTarget, node.name,
        node.receiver is ThisExpression, true);
    node.visitChildren(this);
  }

  @override
  void visitDynamicSet(DynamicSet node) {
    rta.addCall(null, null, node.name, false, true);
    node.visitChildren(this);
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    final target = superclassInfo.getDispatchTarget(Selector(node.name, false));
    if (target != null) {
      rta.addMember(target);
    }
    node.visitChildren(this);
  }

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    final target = superclassInfo.getDispatchTarget(Selector(node.name, false));
    if (target != null) {
      rta.addMember(target);
    }
    node.visitChildren(this);
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    final target = superclassInfo.getDispatchTarget(Selector(node.name, true));
    if (target != null) {
      rta.addMember(target);
    }
    node.visitChildren(this);
  }

  @override
  void visitStaticGet(StaticGet node) {
    rta.addMember(node.target);
    node.visitChildren(this);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    rta.addMember(node.target);
    node.visitChildren(this);
  }

  @override
  void visitStaticSet(StaticSet node) {
    rta.addMember(node.target);
    node.visitChildren(this);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    rta.addMember(node.target);
    node.visitChildren(this);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    // Re-resolve target due to partial mixin resolution.
    for (var replacement in _currentClass!.superclass!.constructors) {
      if (node.target.name == replacement.name) {
        rta.addMember(replacement);
        break;
      }
    }
    node.visitChildren(this);
  }

  @override
  void visitConstantExpression(ConstantExpression node) {
    _constantVisitor.visit(node.constant);
  }
}

class _ConstantVisitor implements ConstantVisitor<void> {
  final RapidTypeAnalysis rta;
  final Set<Constant> visited = {};

  _ConstantVisitor(this.rta);

  void visit(Constant constant) {
    if (visited.add(constant)) {
      constant.accept(this);
    }
  }

  @override
  void visitListConstant(ListConstant constant) {
    for (final entry in constant.entries) {
      visit(entry);
    }
  }

  @override
  void visitMapConstant(MapConstant constant) {
    for (final entry in constant.entries) {
      visit(entry.key);
      visit(entry.value);
    }
  }

  @override
  void visitSetConstant(SetConstant constant) {
    for (final entry in constant.entries) {
      visit(entry);
    }
  }

  @override
  void visitRecordConstant(RecordConstant constant) {
    for (var value in constant.positional) {
      visit(value);
    }
    for (var value in constant.named.values) {
      visit(value);
    }
  }

  @override
  void visitInstanceConstant(InstanceConstant constant) {
    rta.addAllocatedClass(constant.classNode);
    for (var value in constant.fieldValues.values) {
      visit(value);
    }
  }

  void _visitTearOffConstant(TearOffConstant constant) {
    final Member member = constant.target;
    rta.addMember(member);
    if (member is Constructor) {
      rta.addAllocatedClass(member.enclosingClass);
    }
  }

  @override
  void visitStaticTearOffConstant(StaticTearOffConstant constant) =>
      _visitTearOffConstant(constant);

  @override
  void visitConstructorTearOffConstant(ConstructorTearOffConstant constant) =>
      _visitTearOffConstant(constant);

  @override
  void visitRedirectingFactoryTearOffConstant(
          RedirectingFactoryTearOffConstant constant) =>
      _visitTearOffConstant(constant);

  @override
  void visitInstantiationConstant(InstantiationConstant constant) {
    visit(constant.tearOffConstant);
  }

  @override
  void visitNullConstant(NullConstant constant) {}

  @override
  void visitBoolConstant(BoolConstant constant) {}

  @override
  void visitIntConstant(IntConstant constant) {}

  @override
  void visitDoubleConstant(DoubleConstant constant) {}

  @override
  void visitStringConstant(StringConstant constant) {}

  @override
  void visitSymbolConstant(SymbolConstant constant) {}

  @override
  void visitTypeLiteralConstant(TypeLiteralConstant constant) {}

  @override
  void visitTypedefTearOffConstant(TypedefTearOffConstant constant) =>
      throw 'TypedefTearOffConstant is not supported (should be constant evaluated).';

  @override
  void visitUnevaluatedConstant(UnevaluatedConstant constant) =>
      throw 'UnevaluatedConstant is not supported (should be constant evaluated).';

  @override
  void visitAuxiliaryConstant(AuxiliaryConstant constant) {
    throw new UnsupportedError("Unsupported auxiliary constant "
        "${constant} (${constant.runtimeType}).");
  }
}

class _EntryPointsListenerImpl implements EntryPointsListener {
  final RapidTypeAnalysis rta;

  _EntryPointsListenerImpl(this.rta);

  @override
  void addFieldUsedInConstant(Field field, Type instance, Type value) {}

  @override
  void addRawCall(calls.Selector selector) {
    if (selector is calls.DirectSelector) {
      rta.addMember(selector.member);
    } else if (selector is calls.InterfaceSelector) {
      rta.addCall(selector.member.enclosingClass!, selector.member,
          selector.name, selector is calls.VirtualSelector, selector.isSetter);
    } else {
      throw 'Unexpected selector ${selector.runtimeType} $selector';
    }
  }

  @override
  ConcreteType addAllocatedClass(Class c) => rta.addAllocatedClass(c);

  @override
  Field getRecordPositionalField(RecordShape shape, int pos) =>
      throw 'Unsupported operation';

  @override
  Field getRecordNamedField(RecordShape shape, String name) =>
      throw 'Unsupported operation';

  @override
  void recordMemberCalledViaInterfaceSelector(Member target) =>
      throw 'Unsupported operation';

  @override
  void recordMemberCalledViaThis(Member target) =>
      throw 'Unsupported operation';

  @override
  void recordTearOff(Member target) => throw 'Unsupported operation';
}
