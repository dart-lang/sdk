// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../elements/entities.dart';
import '../inferrer/types.dart';
import '../js/js.dart' as js;
import '../js_backend/codegen_inputs.dart';
import '../js_backend/namer_migrated.dart' show operatorNameToIdentifier;
import '../js_model/elements.dart' show JGeneratorBody;
import '../serialization/serialization.dart';
import '../universe/selector.dart';
import '../util/util.dart';

import 'codegen_interfaces.dart' as interfaces;

enum ModularNameKind {
  rtiField,
  className,
  aliasedSuperMember,
  staticClosure,
  methodProperty,
  operatorIs,
  instanceMethod,
  instanceField,
  invocation,
  lazyInitializer,
  globalPropertyNameForClass,
  globalPropertyNameForMember,
  globalNameForInterfaceTypeVariable,
  nameForGetInterceptor,
  nameForOneShotInterceptor,
  asName,
}

class ModularName extends js.Name implements js.AstContainer {
  static const String tag = 'modular-name';

  final ModularNameKind kind;
  js.Name? _value;
  final Object? data;
  final Set<ClassEntity>? set;

  ModularName(this.kind, {this.data, this.set});

  factory ModularName.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ModularNameKind kind = source.readEnum(ModularNameKind.values);
    Object? data;
    Set<ClassEntity>? set;
    switch (kind) {
      case ModularNameKind.rtiField:
        break;
      case ModularNameKind.className:
      case ModularNameKind.operatorIs:
      case ModularNameKind.globalPropertyNameForClass:
        data = source.readClass();
        break;
      case ModularNameKind.aliasedSuperMember:
      case ModularNameKind.staticClosure:
      case ModularNameKind.methodProperty:
      case ModularNameKind.instanceField:
      case ModularNameKind.instanceMethod:
      case ModularNameKind.lazyInitializer:
      case ModularNameKind.globalPropertyNameForMember:
        data = source.readMember();
        break;
      case ModularNameKind.invocation:
        data = Selector.readFromDataSource(source);
        break;
      case ModularNameKind.globalNameForInterfaceTypeVariable:
        data = source.readTypeVariable();
        break;
      case ModularNameKind.nameForGetInterceptor:
        set = source.readClasses().toSet();
        break;
      case ModularNameKind.nameForOneShotInterceptor:
        data = Selector.readFromDataSource(source);
        set = source.readClasses().toSet();
        break;
      case ModularNameKind.asName:
        data = source.readString();
        break;
    }
    source.end(tag);
    return ModularName(kind, data: data, set: set);
  }

  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeEnum(kind);
    switch (kind) {
      case ModularNameKind.rtiField:
        break;
      case ModularNameKind.className:
      case ModularNameKind.operatorIs:
      case ModularNameKind.globalPropertyNameForClass:
        sink.writeClass(data as ClassEntity);
        break;
      case ModularNameKind.aliasedSuperMember:
      case ModularNameKind.staticClosure:
      case ModularNameKind.methodProperty:
      case ModularNameKind.instanceField:
      case ModularNameKind.instanceMethod:
      case ModularNameKind.lazyInitializer:
      case ModularNameKind.globalPropertyNameForMember:
        sink.writeMember(data as MemberEntity);
        break;
      case ModularNameKind.invocation:
        final selector = data as Selector;
        selector.writeToDataSink(sink);
        break;
      case ModularNameKind.globalNameForInterfaceTypeVariable:
        final typeVariable = data as TypeVariableEntity;
        sink.writeTypeVariable(typeVariable);
        break;
      case ModularNameKind.nameForGetInterceptor:
        sink.writeClasses(set);
        break;
      case ModularNameKind.nameForOneShotInterceptor:
        final selector = data as Selector;
        selector.writeToDataSink(sink);
        sink.writeClasses(set);
        break;
      case ModularNameKind.asName:
        sink.writeString(data as String);
        break;
    }
    sink.end(tag);
  }

  @override
  bool get isFinalized => _value != null;

  js.Name get value {
    assert(isFinalized, 'value not set for $this');
    return _value!;
  }

  void set value(js.Name node) {
    assert(!isFinalized);
    assert((node as dynamic) != null);
    _value = node.withSourceInformation(sourceInformation) as js.Name;
  }

  @override
  String get key {
    assert(isFinalized);
    return _value!.key;
  }

  @override
  String get name {
    assert(isFinalized, 'value not set for $this');
    return _value!.name;
  }

  @override
  bool get allowRename {
    assert(isFinalized, 'value not set for $this');
    return _value!.allowRename;
  }

  @override
  Iterable<js.Node> get containedNodes {
    return _value != null ? [_value!] : const [];
  }

  @override
  int get hashCode {
    return Hashing.setHash(set, Hashing.objectsHash(kind, data));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModularName &&
        kind == other.kind &&
        data == other.data &&
        equalSets(set, other.set);
  }

  @override
  String toString() =>
      'ModularName(kind=$kind, data=$data, value=${_value?.key})';

  @override
  String nonfinalizedDebugText() {
    switch (kind) {
      case ModularNameKind.rtiField:
        return r'ModularName"$ti"';
      case ModularNameKind.instanceField:
        return 'ModularName"field:${(data as Entity).name}"';
      case ModularNameKind.instanceMethod:
        return 'ModularName"${_instanceMethodName(data as MemberEntity)}"';
      case ModularNameKind.methodProperty:
        return 'ModularName"methodProperty:${(data as Entity).name}"';
      case ModularNameKind.operatorIs:
        return 'ModularName"is:${_className(data as ClassEntity)}"';
      case ModularNameKind.className:
        return 'ModularName"class:${_className(data as ClassEntity)}"';
      case ModularNameKind.globalPropertyNameForClass:
        return 'ModularName"classref:${_className(data as ClassEntity)}"';
      case ModularNameKind.aliasedSuperMember:
        MemberEntity member = (data as MemberEntity);
        String className = _className(member.enclosingClass!);
        String invocationName = operatorNameToIdentifier(member.name)!;
        final description = "$className.$invocationName";
        return 'ModularName"alias:$description"';
      case ModularNameKind.staticClosure:
        return 'ModularName"closure:${_qualifiedStaticName(data as MemberEntity)}"';
      case ModularNameKind.lazyInitializer:
        return 'ModularName"lazy:${(data as MemberEntity).name}"';
      case ModularNameKind.globalPropertyNameForMember:
        MemberEntity member = data as MemberEntity;
        return 'ModularName"ref:${_qualifiedStaticName(member)}"';
      case ModularNameKind.invocation:
        return 'ModularName"selector:${_selectorText(data as Selector)}"';
      case ModularNameKind.nameForOneShotInterceptor:
        return 'ModularName"oneshot:${_selectorText(data as Selector)}"';
      case ModularNameKind.globalNameForInterfaceTypeVariable:
        break;
      case ModularNameKind.nameForGetInterceptor:
        return 'ModularName"getInterceptor"';
      case ModularNameKind.asName:
        return 'ModularName"asName:$data"';
    }
    return super.nonfinalizedDebugText();
  }

  String _className(ClassEntity cls) {
    return cls.name.replaceAll('&', '_');
  }

  String _qualifiedStaticName(MemberEntity member) {
    if (member.isConstructor || member.isStatic) {
      return '${_className(member.enclosingClass!)}.${member.name!}';
    }
    return member.name!;
  }

  String _instanceMethodInvocationName(MemberEntity member) {
    String invocationName = operatorNameToIdentifier(member.name)!;
    if (member.isGetter) invocationName = r'get$' + invocationName;
    if (member.isSetter) invocationName = r'set$' + invocationName;
    return invocationName;
  }

  String _instanceMethodName(MemberEntity member) {
    if (member is ConstructorBodyEntity) {
      return 'constructorBody:${_qualifiedStaticName(member.constructor)}';
    }
    if (member is JGeneratorBody) {
      MemberEntity function = member.function;
      return 'generatorBody:'
          '${_className(function.enclosingClass!)}.'
          '${_instanceMethodInvocationName(function)}';
    }
    return 'instanceMethod:${_instanceMethodInvocationName(member)}';
  }

  String _selectorText(Selector selector) {
    // Approximation to unminified selector.
    if (selector.isGetter) return r'get$' + selector.name;
    if (selector.isSetter) return r'set$' + selector.name;
    if (selector.isOperator || selector.isIndex || selector.isIndexSet) {
      return operatorNameToIdentifier(selector.name)!;
    }
    List<String> parts = [
      selector.name,
      if (selector.callStructure.typeArgumentCount > 0)
        '${selector.callStructure.typeArgumentCount}',
      '${selector.callStructure.argumentCount}',
      ...selector.callStructure.getOrderedNamedArguments()
    ];
    return parts.join(r'$');
  }
}

/// Interface for reading the code generation results for all [MemberEntity]s.
abstract class CodegenResults {
  GlobalTypeInferenceResults get globalTypeInferenceResults;
  CodegenInputs get codegenInputs;
  interfaces.CodegenResult getCodegenResults(MemberEntity member);
}

/// Deserialized code generation results.
///
/// This is used for modular code generation.
class DeserializedCodegenResults extends CodegenResults {
  @override
  final GlobalTypeInferenceResults globalTypeInferenceResults;
  @override
  final CodegenInputs codegenInputs;

  final Map<MemberEntity, interfaces.CodegenResult> _map;

  DeserializedCodegenResults(
      this.globalTypeInferenceResults, this.codegenInputs, this._map);

  @override
  interfaces.CodegenResult getCodegenResults(MemberEntity member) {
    return _map[member]!;
  }
}
