// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_item.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';

class BaseNameConflict extends BaseNameMembers {
  final ManifestItemId id;

  factory BaseNameConflict() {
    return BaseNameConflict._(id: ManifestItemId.generate());
  }

  factory BaseNameConflict.read(SummaryDataReader reader) {
    return BaseNameConflict._(id: ManifestItemId.read(reader));
  }

  BaseNameConflict._({required this.id});

  @override
  BaseNameMembers addDeclaredConstructor(
    InterfaceItemConstructorItem constructor,
  ) {
    return this;
  }

  @override
  BaseNameMembers addDeclaredGetter(InstanceItemGetterItem getter) {
    return this;
  }

  @override
  BaseNameMembers addDeclaredIndexEq(InstanceItemMethodItem method) {
    return this;
  }

  @override
  BaseNameMembers addDeclaredMethod(InstanceItemMethodItem method) {
    return this;
  }

  @override
  BaseNameMembers addDeclaredSetter(InstanceItemSetterItem setter) {
    return this;
  }

  @override
  BaseNameMembers addInheritedConstructor(ManifestItemId id) {
    return this;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_BaseNameItemsKind.conflict);
    id.write(sink);
  }
}

class BaseNameConstructor extends BaseNameMembers {
  final DeclaredOrInheritedConstructor constructor;

  BaseNameConstructor({required this.constructor});

  factory BaseNameConstructor.read(SummaryDataReader reader) {
    return BaseNameConstructor(
      constructor: DeclaredOrInheritedConstructor.read(reader),
    );
  }

  @override
  ManifestItemId get constructorId => constructor.id;

  @override
  InterfaceItemConstructorItem? get declaredConstructor {
    return constructor.item;
  }

  @override
  BaseNameMembers addDeclaredConstructor(
    InterfaceItemConstructorItem constructor,
  ) {
    return BaseNameConflict();
  }

  @override
  BaseNameMembers addDeclaredGetter(InstanceItemGetterItem getter) {
    if (getter.isStatic) {
      return BaseNameConflict();
    } else {
      return BaseNameConstructorGetter(
        constructor: constructor,
        getter: getter,
      );
    }
  }

  @override
  BaseNameMembers addDeclaredMethod(InstanceItemMethodItem method) {
    if (method.isStatic) {
      return BaseNameConflict();
    } else {
      return BaseNameConstructorMethod(
        constructor: constructor,
        method: method,
      );
    }
  }

  @override
  BaseNameMembers addDeclaredSetter(InstanceItemSetterItem setter) {
    if (setter.isStatic) {
      return BaseNameConflict();
    } else {
      return BaseNameConstructorSetter(
        constructor: constructor,
        setter: setter,
      );
    }
  }

  @override
  BaseNameMembers addInheritedConstructor(ManifestItemId id) {
    return BaseNameConflict();
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_BaseNameItemsKind.constructor);
    constructor.write(sink);
  }
}

class BaseNameConstructorGetter extends BaseNameMembers {
  final DeclaredOrInheritedConstructor constructor;
  final InstanceItemGetterItem getter;

  BaseNameConstructorGetter({required this.constructor, required this.getter})
    : assert(!getter.isStatic);

  factory BaseNameConstructorGetter.read(SummaryDataReader reader) {
    return BaseNameConstructorGetter(
      constructor: DeclaredOrInheritedConstructor.read(reader),
      getter: InstanceItemGetterItem.read(reader),
    );
  }

  @override
  ManifestItemId get constructorId => constructor.id;

  @override
  InterfaceItemConstructorItem? get declaredConstructor {
    return constructor.item;
  }

  @override
  InstanceItemGetterItem get declaredGetter {
    return getter;
  }

  @override
  ManifestItemId get getterOrMethodId => getter.id;

  @override
  BaseNameMembers addDeclaredGetter(InstanceItemGetterItem getter) {
    return BaseNameConflict();
  }

  @override
  BaseNameMembers addDeclaredSetter(InstanceItemSetterItem setter) {
    if (setter.isStatic) {
      return BaseNameConflict();
    } else {
      return BaseNameConstructorGetterSetter(
        constructor: constructor,
        getter: getter,
        setter: setter,
      );
    }
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_BaseNameItemsKind.constructorGetter);
    constructor.write(sink);
    getter.write(sink);
  }
}

class BaseNameConstructorGetterSetter extends BaseNameMembers {
  final DeclaredOrInheritedConstructor constructor;
  final InstanceItemGetterItem getter;
  final InstanceItemSetterItem setter;

  BaseNameConstructorGetterSetter({
    required this.constructor,
    required this.getter,
    required this.setter,
  }) : assert(!getter.isStatic),
       assert(!setter.isStatic);

  factory BaseNameConstructorGetterSetter.read(SummaryDataReader reader) {
    return BaseNameConstructorGetterSetter(
      constructor: DeclaredOrInheritedConstructor.read(reader),
      getter: InstanceItemGetterItem.read(reader),
      setter: InstanceItemSetterItem.read(reader),
    );
  }

  @override
  ManifestItemId get constructorId => constructor.id;

  @override
  InterfaceItemConstructorItem? get declaredConstructor {
    return constructor.item;
  }

  @override
  InstanceItemGetterItem get declaredGetter {
    return getter;
  }

  @override
  InstanceItemSetterItem get declaredSetter {
    return setter;
  }

  @override
  ManifestItemId get getterOrMethodId => getter.id;

  @override
  ManifestItemId get setterId => setter.id;

  @override
  BaseNameMembers addDeclaredSetter(InstanceItemSetterItem setter) {
    return BaseNameConflict();
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_BaseNameItemsKind.constructorGetterSetter);
    constructor.write(sink);
    getter.write(sink);
    setter.write(sink);
  }
}

class BaseNameConstructorMethod extends BaseNameMembers {
  final DeclaredOrInheritedConstructor constructor;
  final InstanceItemMethodItem method;

  BaseNameConstructorMethod({required this.constructor, required this.method})
    : assert(!method.isStatic);

  factory BaseNameConstructorMethod.read(SummaryDataReader reader) {
    return BaseNameConstructorMethod(
      constructor: DeclaredOrInheritedConstructor.read(reader),
      method: InstanceItemMethodItem.read(reader),
    );
  }

  @override
  ManifestItemId get constructorId => constructor.id;

  @override
  InterfaceItemConstructorItem? get declaredConstructor {
    return constructor.item;
  }

  @override
  InstanceItemMethodItem get declaredMethod {
    return method;
  }

  @override
  ManifestItemId get getterOrMethodId => method.id;

  @override
  BaseNameMembers addDeclaredGetter(InstanceItemGetterItem getter) {
    return BaseNameConflict();
  }

  @override
  BaseNameMembers addDeclaredMethod(InstanceItemMethodItem method) {
    return BaseNameConflict();
  }

  @override
  BaseNameMembers addDeclaredSetter(InstanceItemSetterItem setter) {
    return BaseNameConflict();
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_BaseNameItemsKind.constructorMethod);
    constructor.write(sink);
    method.write(sink);
  }
}

class BaseNameConstructorSetter extends BaseNameMembers {
  final DeclaredOrInheritedConstructor constructor;
  final InstanceItemSetterItem setter;

  BaseNameConstructorSetter({required this.constructor, required this.setter})
    : assert(!setter.isStatic);

  factory BaseNameConstructorSetter.read(SummaryDataReader reader) {
    return BaseNameConstructorSetter(
      constructor: DeclaredOrInheritedConstructor.read(reader),
      setter: InstanceItemSetterItem.read(reader),
    );
  }

  @override
  ManifestItemId get constructorId => constructor.id;

  @override
  InterfaceItemConstructorItem? get declaredConstructor {
    return constructor.item;
  }

  @override
  InstanceItemSetterItem get declaredSetter {
    return setter;
  }

  @override
  ManifestItemId get setterId => setter.id;

  @override
  BaseNameMembers addDeclaredSetter(InstanceItemSetterItem setter) {
    return BaseNameConflict();
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_BaseNameItemsKind.constructorSetter);
    constructor.write(sink);
    setter.write(sink);
  }
}

class BaseNameGetter extends BaseNameMembers {
  final InstanceItemGetterItem getter;

  BaseNameGetter({required this.getter});

  factory BaseNameGetter.read(SummaryDataReader reader) {
    return BaseNameGetter(getter: InstanceItemGetterItem.read(reader));
  }

  @override
  InstanceItemGetterItem get declaredGetter {
    return getter;
  }

  @override
  ManifestItemId get getterOrMethodId => getter.id;

  @override
  BaseNameMembers addDeclaredGetter(InstanceItemGetterItem getter) {
    return BaseNameConflict();
  }

  @override
  BaseNameMembers addDeclaredSetter(InstanceItemSetterItem setter) {
    if (getter.isStatic != setter.isStatic) {
      return BaseNameConflict();
    }
    return BaseNameGetterSetter(getter: getter, setter: setter);
  }

  @override
  BaseNameMembers addInheritedConstructor(ManifestItemId id) {
    if (getter.isStatic) {
      return BaseNameConflict();
    } else {
      return BaseNameConstructorGetter(
        constructor: InheritedConstructor(id),
        getter: getter,
      );
    }
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_BaseNameItemsKind.getter);
    getter.write(sink);
  }
}

class BaseNameGetterSetter extends BaseNameMembers {
  final InstanceItemGetterItem getter;
  final InstanceItemSetterItem setter;

  BaseNameGetterSetter({required this.getter, required this.setter})
    : assert(
        getter.isStatic == setter.isStatic,
        'Getter and setter must have the same static modifier.',
      );

  factory BaseNameGetterSetter.read(SummaryDataReader reader) {
    return BaseNameGetterSetter(
      getter: InstanceItemGetterItem.read(reader),
      setter: InstanceItemSetterItem.read(reader),
    );
  }

  @override
  InstanceItemGetterItem get declaredGetter {
    return getter;
  }

  @override
  InstanceItemSetterItem get declaredSetter {
    return setter;
  }

  @override
  ManifestItemId get getterOrMethodId => getter.id;

  @override
  ManifestItemId get setterId => setter.id;

  @override
  BaseNameMembers addDeclaredSetter(InstanceItemSetterItem setter) {
    return BaseNameConflict();
  }

  @override
  BaseNameMembers addInheritedConstructor(ManifestItemId id) {
    if (getter.isStatic || setter.isStatic) {
      return BaseNameConflict();
    } else {
      return BaseNameConstructorGetterSetter(
        constructor: InheritedConstructor(id),
        getter: getter,
        setter: setter,
      );
    }
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_BaseNameItemsKind.getterSetter);
    getter.write(sink);
    setter.write(sink);
  }
}

class BaseNameIndexEq extends BaseNameMembers {
  final InstanceItemMethodItem indexEq;

  BaseNameIndexEq({required this.indexEq});

  factory BaseNameIndexEq.read(SummaryDataReader reader) {
    return BaseNameIndexEq(indexEq: InstanceItemMethodItem.read(reader));
  }

  @override
  InstanceItemMethodItem get declaredIndexEq {
    return indexEq;
  }

  @override
  ManifestItemId get indexEqId => indexEq.id;

  @override
  BaseNameMembers addDeclaredIndexEq(InstanceItemMethodItem method) {
    return BaseNameConflict();
  }

  @override
  BaseNameMembers addDeclaredMethod(InstanceItemMethodItem method) {
    return BaseNameMethodIndexEq(method: method, indexEq: indexEq);
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_BaseNameItemsKind.indexEq);
    indexEq.write(sink);
  }
}

sealed class BaseNameMembers {
  BaseNameMembers();

  factory BaseNameMembers.read(SummaryDataReader reader) {
    var kind = reader.readEnum(_BaseNameItemsKind.values);
    switch (kind) {
      case _BaseNameItemsKind.conflict:
        return BaseNameConflict.read(reader);
      case _BaseNameItemsKind.constructor:
        return BaseNameConstructor.read(reader);
      case _BaseNameItemsKind.constructorGetter:
        return BaseNameConstructorGetter.read(reader);
      case _BaseNameItemsKind.constructorGetterSetter:
        return BaseNameConstructorGetterSetter.read(reader);
      case _BaseNameItemsKind.constructorMethod:
        return BaseNameConstructorMethod.read(reader);
      case _BaseNameItemsKind.constructorSetter:
        return BaseNameConstructorSetter.read(reader);
      case _BaseNameItemsKind.getter:
        return BaseNameGetter.read(reader);
      case _BaseNameItemsKind.getterSetter:
        return BaseNameGetterSetter.read(reader);
      case _BaseNameItemsKind.method:
        return BaseNameMethod.read(reader);
      case _BaseNameItemsKind.methodIndexEq:
        return BaseNameMethodIndexEq.read(reader);
      case _BaseNameItemsKind.indexEq:
        return BaseNameIndexEq.read(reader);
      case _BaseNameItemsKind.setter:
        return BaseNameSetter.read(reader);
    }
  }

  ManifestItemId? get constructorId => null;

  InterfaceItemConstructorItem? get declaredConstructor => null;

  InstanceItemGetterItem? get declaredGetter => null;

  InstanceItemMethodItem? get declaredIndexEq => null;

  InstanceItemMethodItem? get declaredMethod => null;

  InstanceItemSetterItem? get declaredSetter => null;

  ManifestItemId? get getterOrMethodId => null;

  ManifestItemId? get indexEqId => null;

  ManifestItemId? get setterId => null;

  BaseNameMembers addDeclaredConstructor(
    InterfaceItemConstructorItem constructor,
  ) {
    _unexpectedTransition();
  }

  BaseNameMembers addDeclaredGetter(InstanceItemGetterItem getter) {
    _unexpectedTransition();
  }

  BaseNameMembers addDeclaredIndexEq(InstanceItemMethodItem method) {
    _unexpectedTransition();
  }

  BaseNameMembers addDeclaredMethod(InstanceItemMethodItem method) {
    _unexpectedTransition();
  }

  BaseNameMembers addDeclaredSetter(InstanceItemSetterItem setter) {
    _unexpectedTransition();
  }

  BaseNameMembers addInheritedConstructor(ManifestItemId id) {
    _unexpectedTransition();
  }

  void write(BufferedSink sink);

  /// The current implementation iterates over members in a specific order:
  /// 1. declared constructors
  /// 2. declared methods
  /// 3. declared getters
  /// 4. declared setters
  /// 5. inherited constructors
  /// 6. inherited methods
  /// 7. inherited getters
  /// 8. inherited setters
  ///
  /// So, not all transitions are possible.
  ///
  /// For example we should never transit with [addDeclaredMethod] from
  /// [BaseNameGetter]. Correspondingly, it is impossible to test such method
  /// implementation, and instead of leaving it and make an impression that
  /// it works, we throw an exception.
  Never _unexpectedTransition() {
    throw StateError('Transition from $runtimeType');
  }

  static Map<BaseName, BaseNameMembers> readMap(SummaryDataReader reader) {
    return reader.readMap(
      readKey: () => BaseName.read(reader),
      readValue: () => BaseNameMembers.read(reader),
    );
  }
}

class BaseNameMethod extends BaseNameMembers {
  final InstanceItemMethodItem method;

  BaseNameMethod({required this.method});

  factory BaseNameMethod.read(SummaryDataReader reader) {
    return BaseNameMethod(method: InstanceItemMethodItem.read(reader));
  }

  @override
  InstanceItemMethodItem get declaredMethod {
    return method;
  }

  @override
  ManifestItemId get getterOrMethodId => method.id;

  @override
  BaseNameMembers addDeclaredGetter(InstanceItemGetterItem getter) {
    return BaseNameConflict();
  }

  @override
  BaseNameMembers addDeclaredIndexEq(InstanceItemMethodItem indexEq) {
    return BaseNameMethodIndexEq(method: method, indexEq: indexEq);
  }

  @override
  BaseNameMembers addDeclaredMethod(InstanceItemMethodItem method) {
    return BaseNameConflict();
  }

  @override
  BaseNameMembers addDeclaredSetter(InstanceItemSetterItem setter) {
    return BaseNameConflict();
  }

  @override
  BaseNameMembers addInheritedConstructor(ManifestItemId id) {
    if (method.isStatic) {
      return BaseNameConflict();
    } else {
      return BaseNameConstructorMethod(
        constructor: InheritedConstructor(id),
        method: method,
      );
    }
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_BaseNameItemsKind.method);
    method.write(sink);
  }
}

class BaseNameMethodIndexEq extends BaseNameMembers {
  final InstanceItemMethodItem method;
  final InstanceItemMethodItem indexEq;

  BaseNameMethodIndexEq({required this.method, required this.indexEq});

  factory BaseNameMethodIndexEq.read(SummaryDataReader reader) {
    return BaseNameMethodIndexEq(
      method: InstanceItemMethodItem.read(reader),
      indexEq: InstanceItemMethodItem.read(reader),
    );
  }

  @override
  InstanceItemMethodItem get declaredIndexEq {
    return indexEq;
  }

  @override
  InstanceItemMethodItem get declaredMethod {
    return method;
  }

  @override
  ManifestItemId get getterOrMethodId => method.id;

  @override
  ManifestItemId get indexEqId => indexEq.id;

  @override
  BaseNameMembers addDeclaredIndexEq(InstanceItemMethodItem method) {
    return BaseNameConflict();
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_BaseNameItemsKind.methodIndexEq);
    method.write(sink);
    indexEq.write(sink);
  }
}

class BaseNameSetter extends BaseNameMembers {
  final InstanceItemSetterItem setter;

  BaseNameSetter({required this.setter});

  factory BaseNameSetter.read(SummaryDataReader reader) {
    return BaseNameSetter(setter: InstanceItemSetterItem.read(reader));
  }

  @override
  InstanceItemSetterItem get declaredSetter {
    return setter;
  }

  @override
  ManifestItemId get setterId => setter.id;

  @override
  BaseNameMembers addDeclaredSetter(InstanceItemSetterItem setter) {
    return BaseNameConflict();
  }

  @override
  BaseNameMembers addInheritedConstructor(ManifestItemId id) {
    if (setter.isStatic) {
      return BaseNameConflict();
    } else {
      return BaseNameConstructorSetter(
        constructor: InheritedConstructor(id),
        setter: setter,
      );
    }
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_BaseNameItemsKind.setter);
    setter.write(sink);
  }
}

class DeclaredConstructor extends DeclaredOrInheritedConstructor {
  @override
  final InterfaceItemConstructorItem item;

  DeclaredConstructor(this.item);

  factory DeclaredConstructor.read(SummaryDataReader reader) {
    return DeclaredConstructor(InterfaceItemConstructorItem.read(reader));
  }

  @override
  ManifestItemId get id => item.id;

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_DeclaredOrInheritedKind.declared);
    item.write(sink);
  }
}

sealed class DeclaredOrInheritedConstructor {
  DeclaredOrInheritedConstructor();

  factory DeclaredOrInheritedConstructor.read(SummaryDataReader reader) {
    var kind = reader.readEnum(_DeclaredOrInheritedKind.values);
    switch (kind) {
      case _DeclaredOrInheritedKind.declared:
        return DeclaredConstructor.read(reader);
      case _DeclaredOrInheritedKind.inherited:
        return InheritedConstructor.read(reader);
    }
  }

  ManifestItemId get id;

  InterfaceItemConstructorItem? get item => null;

  void write(BufferedSink sink);
}

class InheritedConstructor extends DeclaredOrInheritedConstructor {
  @override
  final ManifestItemId id;

  InheritedConstructor(this.id);

  factory InheritedConstructor.read(SummaryDataReader reader) {
    return InheritedConstructor(ManifestItemId.read(reader));
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_DeclaredOrInheritedKind.inherited);
    id.write(sink);
  }
}

enum _BaseNameItemsKind {
  conflict,
  constructor,
  constructorGetter,
  constructorGetterSetter,
  constructorMethod,
  constructorSetter,
  getter,
  getterSetter,
  indexEq,
  method,
  methodIndexEq,
  setter,
}

enum _DeclaredOrInheritedKind { declared, inherited }

extension BaseNameItemsMapExtension on Map<BaseName, BaseNameMembers> {
  void addDeclaredConstructor(
    BaseName name,
    InterfaceItemConstructorItem constructor,
  ) {
    var existing = this[name];
    if (existing == null) {
      this[name] = BaseNameConstructor(
        constructor: DeclaredConstructor(constructor),
      );
    } else {
      this[name] = existing.addDeclaredConstructor(constructor);
    }
  }

  void addDeclaredGetter(BaseName name, InstanceItemGetterItem getter) {
    var existing = this[name];
    if (existing == null) {
      this[name] = BaseNameGetter(getter: getter);
    } else {
      this[name] = existing.addDeclaredGetter(getter);
    }
  }

  void addDeclaredIndexEq(BaseName name, InstanceItemMethodItem method) {
    var existing = this[name];
    if (existing == null) {
      this[name] = BaseNameIndexEq(indexEq: method);
    } else {
      this[name] = existing.addDeclaredIndexEq(method);
    }
  }

  void addDeclaredMethod(BaseName name, InstanceItemMethodItem method) {
    var existing = this[name];
    if (existing == null) {
      this[name] = BaseNameMethod(method: method);
    } else {
      this[name] = existing.addDeclaredMethod(method);
    }
  }

  void addDeclaredSetter(BaseName name, InstanceItemSetterItem setter) {
    var existing = this[name];
    if (existing == null) {
      this[name] = BaseNameSetter(setter: setter);
    } else {
      this[name] = existing.addDeclaredSetter(setter);
    }
  }

  void addInheritedConstructor(BaseName name, ManifestItemId id) {
    var existing = this[name];
    if (existing == null) {
      this[name] = BaseNameConstructor(constructor: InheritedConstructor(id));
    } else {
      this[name] = existing.addInheritedConstructor(id);
    }
  }

  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }
}
