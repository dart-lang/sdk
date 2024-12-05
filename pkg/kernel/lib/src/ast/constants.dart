// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

// ------------------------------------------------------------------------
//                             CONSTANTS
// ------------------------------------------------------------------------

sealed class Constant extends Node {
  /// Calls the `visit*ConstantReference()` method on visitor [v] for all
  /// constants referenced in this constant.
  ///
  /// (Note that a constant can be seen as a DAG (directed acyclic graph) and
  ///  not a tree!)
  @override
  void visitChildren(Visitor v);

  /// Calls the `visit*Constant()` method on the visitor [v].
  @override
  R accept<R>(ConstantVisitor<R> v);

  /// Calls the `visit*Constant()` method on the visitor [v].
  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg);

  /// Calls the `visit*ConstantReference()` method on the visitor [v].
  R acceptReference<R>(ConstantReferenceVisitor<R> v);

  /// Calls the `visit*ConstantReference()` method on the visitor [v].
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg);

  /// The Kernel AST will reference [Constant]s via [ConstantExpression]s.  The
  /// constants are not required to be canonicalized, but they have to be deeply
  /// comparable via hashCode/==!
  @override
  int get hashCode;

  @override
  bool operator ==(Object other);

  @override
  String toString() => throw '$runtimeType';

  /// Returns a textual representation of the this constant.
  ///
  /// If [verbose] is `true`, qualified names will include the library name/uri.
  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    printer.writeConstant(this);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer);

  /// Gets the type of this constant.
  DartType getType(StaticTypeContext context);
}

abstract class AuxiliaryConstant extends Constant {
  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitAuxiliaryConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitAuxiliaryConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitAuxiliaryConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitAuxiliaryConstantReference(this, arg);
}

sealed class PrimitiveConstant<T> extends Constant {
  final T value;

  PrimitiveConstant(this.value);

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) =>
      other is PrimitiveConstant<T> && other.value == value;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('$value');
  }
}

class NullConstant extends PrimitiveConstant<Null> {
  NullConstant() : super(null);

  @override
  void visitChildren(Visitor v) {}

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitNullConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitNullConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitNullConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitNullConstantReference(this, arg);

  @override
  DartType getType(StaticTypeContext context) => const NullType();

  @override
  String toString() => 'NullConstant(${toStringInternal()})';
}

class BoolConstant extends PrimitiveConstant<bool> {
  BoolConstant(bool value) : super(value);

  @override
  void visitChildren(Visitor v) {}

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitBoolConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitBoolConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitBoolConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitBoolConstantReference(this, arg);

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.boolRawType(context.nonNullable);

  @override
  String toString() => 'BoolConstant(${toStringInternal()})';
}

/// An integer constant on a non-JS target.
class IntConstant extends PrimitiveConstant<int> {
  IntConstant(int value) : super(value);

  @override
  void visitChildren(Visitor v) {}

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitIntConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitIntConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitIntConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitIntConstantReference(this, arg);

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.intRawType(context.nonNullable);

  @override
  String toString() => 'IntConstant(${toStringInternal()})';
}

/// A double constant on a non-JS target or any numeric constant on a JS target.
class DoubleConstant extends PrimitiveConstant<double> {
  DoubleConstant(double value) : super(value);

  @override
  void visitChildren(Visitor v) {}

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitDoubleConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitDoubleConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitDoubleConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitDoubleConstantReference(this, arg);

  @override
  int get hashCode => value.isNaN ? 199 : super.hashCode;

  @override
  bool operator ==(Object other) =>
      other is DoubleConstant && identical(value, other.value);

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.doubleRawType(context.nonNullable);

  @override
  String toString() => 'DoubleConstant(${toStringInternal()})';
}

class StringConstant extends PrimitiveConstant<String> {
  StringConstant(String value) : super(value);

  @override
  void visitChildren(Visitor v) {}

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitStringConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitStringConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitStringConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitStringConstantReference(this, arg);

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.stringRawType(context.nonNullable);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('"');
    printer.write(escapeString(value));
    printer.write('"');
  }

  @override
  String toString() => 'StringConstant(${toStringInternal()})';
}

class SymbolConstant extends Constant {
  final String name;
  final Reference? libraryReference;

  SymbolConstant(this.name, this.libraryReference);

  @override
  void visitChildren(Visitor v) {}

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitSymbolConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitSymbolConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitSymbolConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitSymbolConstantReference(this, arg);

  @override
  String toString() => 'SymbolConstant(${toStringInternal()})';

  @override
  int get hashCode => _Hash.hash2(name, libraryReference);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SymbolConstant &&
          other.name == name &&
          other.libraryReference == libraryReference);

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.symbolRawType(context.nonNullable);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('#');
    if (printer.includeAuxiliaryProperties && libraryReference != null) {
      printer.write(libraryNameToString(libraryReference!.asLibrary));
      printer.write('::');
    }
    printer.write(name);
  }
}

class MapConstant extends Constant {
  final DartType keyType;
  final DartType valueType;
  final List<ConstantMapEntry> entries;

  MapConstant(this.keyType, this.valueType, this.entries);

  @override
  void visitChildren(Visitor v) {
    keyType.accept(v);
    valueType.accept(v);
    for (final ConstantMapEntry entry in entries) {
      entry.key.acceptReference(v);
      entry.value.acceptReference(v);
    }
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitMapConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitMapConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitMapConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitMapConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('const <');
    printer.writeType(keyType);
    printer.write(', ');
    printer.writeType(valueType);
    printer.write('>{');
    for (int i = 0; i < entries.length; i++) {
      if (i > 0) {
        printer.write(', ');
      }
      printer.writeConstantMapEntry(entries[i]);
    }
    printer.write('}');
  }

  @override
  String toString() => 'MapConstant(${toStringInternal()})';

  @override
  late final int hashCode = _Hash.combine2Finish(
      keyType.hashCode, valueType.hashCode, _Hash.combineListHash(entries));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MapConstant &&
          other.keyType == keyType &&
          other.valueType == valueType &&
          listEquals(other.entries, entries));

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.mapType(keyType, valueType, context.nonNullable);
}

class ConstantMapEntry {
  final Constant key;
  final Constant value;
  ConstantMapEntry(this.key, this.value);

  @override
  String toString() => 'ConstantMapEntry(${toStringInternal()})';

  @override
  int get hashCode => _Hash.hash2(key, value);

  @override
  bool operator ==(Object other) =>
      other is ConstantMapEntry && other.key == key && other.value == value;

  String toStringInternal() => toText(defaultAstTextStrategy);

  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    printer.writeConstantMapEntry(this);
    return printer.getText();
  }

  void toTextInternal(AstPrinter printer) {
    printer.writeConstant(key);
    printer.write(': ');
    printer.writeConstant(value);
  }
}

class ListConstant extends Constant {
  final DartType typeArgument;
  final List<Constant> entries;

  ListConstant(this.typeArgument, this.entries);

  @override
  void visitChildren(Visitor v) {
    typeArgument.accept(v);
    for (final Constant constant in entries) {
      constant.acceptReference(v);
    }
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitListConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitListConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitListConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitListConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('const <');
    printer.writeType(typeArgument);
    printer.write('>[');
    for (int i = 0; i < entries.length; i++) {
      if (i > 0) {
        printer.write(', ');
      }
      printer.writeConstant(entries[i]);
    }
    printer.write(']');
  }

  @override
  String toString() => 'ListConstant(${toStringInternal()})';

  @override
  late final int hashCode = _Hash.combineFinish(
      typeArgument.hashCode, _Hash.combineListHash(entries));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListConstant &&
          other.typeArgument == typeArgument &&
          listEquals(other.entries, entries));

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.listType(typeArgument, context.nonNullable);
}

class SetConstant extends Constant {
  final DartType typeArgument;
  final List<Constant> entries;

  SetConstant(this.typeArgument, this.entries);

  @override
  void visitChildren(Visitor v) {
    typeArgument.accept(v);
    for (final Constant constant in entries) {
      constant.acceptReference(v);
    }
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitSetConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitSetConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitSetConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitSetConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('const <');
    printer.writeType(typeArgument);
    printer.write('>{');
    for (int i = 0; i < entries.length; i++) {
      if (i > 0) {
        printer.write(', ');
      }
      printer.writeConstant(entries[i]);
    }
    printer.write('}');
  }

  @override
  String toString() => 'SetConstant(${toStringInternal()})';

  @override
  late final int hashCode = _Hash.combineFinish(
      typeArgument.hashCode, _Hash.combineListHash(entries));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetConstant &&
          other.typeArgument == typeArgument &&
          listEquals(other.entries, entries));

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.setType(typeArgument, context.nonNullable);
}

class RecordConstant extends Constant {
  /// Positional field values.
  final List<Constant> positional;

  /// Named field values, sorted by name.
  final Map<String, Constant> named;

  /// The runtime type of the constant.
  ///
  /// [recordType] is computed from the individual types of the record fields
  /// and reflects runtime type of the record constant, as opposed to the
  /// static type of the expression that defined the constant.
  ///
  /// The following program shows the distinction between the static and the
  /// runtime types of the constant. The static type of the first record in the
  /// invocation of `identical` is `(E, String)`, the static type of the second
  /// — `(int, String)`. The runtime type of both constants is `(int, String)`,
  /// and the assertion condition should be satisfied.
  ///
  ///   extension type const E(Object? it) {}
  ///
  ///   main() {
  ///     const bool check = identical(const (E(1), "foo"), const (1, "foo"));
  ///     assert(check);
  ///   }
  final RecordType recordType;

  RecordConstant(this.positional, this.named, this.recordType)
      : assert(positional.length == recordType.positional.length &&
            named.length == recordType.named.length &&
            recordType.named
                .map((f) => f.name)
                .toSet()
                .containsAll(named.keys)),
        assert(() {
          // Assert that the named fields are sorted.
          String? previous;
          for (String name in named.keys) {
            if (previous != null && name.compareTo(previous) < 0) {
              return false;
            }
            previous = name;
          }
          return true;
        }(),
            "Named fields of a RecordConstant aren't sorted lexicographically: "
            "${named.keys.join(", ")}");

  RecordConstant.fromTypeContext(
      this.positional, this.named, StaticTypeContext staticTypeContext)
      : recordType = new RecordType([
          for (Constant constant in positional)
            constant.getType(staticTypeContext)
        ], [
          for (var MapEntry(key: name, value: constant) in named.entries)
            new NamedType(name, constant.getType(staticTypeContext))
        ], staticTypeContext.nonNullable);

  @override
  void visitChildren(Visitor v) {
    recordType.accept(v);
    for (final Constant entry in positional) {
      entry.acceptReference(v);
    }
    for (final Constant entry in named.values) {
      entry.acceptReference(v);
    }
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitRecordConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitRecordConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitRecordConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitRecordConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write("const (");
    String comma = '';
    for (Constant entry in positional) {
      printer.write(comma);
      printer.writeConstant(entry);
      comma = ', ';
    }
    if (named.isNotEmpty) {
      printer.write(comma);
      comma = '';
      printer.write("{");
      for (MapEntry<String, Constant> entry in named.entries) {
        printer.write(comma);
        printer.write(entry.key);
        printer.write(": ");
        printer.writeConstant(entry.value);
        comma = ', ';
      }
      printer.write("}");
    }
    printer.write(")");
  }

  @override
  String toString() => "RecordConstant(${toStringInternal()})";

  @override
  late final int hashCode =
      _Hash.combineMapHashUnordered(named, _Hash.combineListHash(positional));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordConstant &&
          listEquals(other.positional, positional) &&
          mapEquals(other.named, named));

  @override
  DartType getType(StaticTypeContext context) => recordType;
}

class InstanceConstant extends Constant {
  final Reference classReference;
  final List<DartType> typeArguments;
  final Map<Reference, Constant> fieldValues;

  InstanceConstant(this.classReference, this.typeArguments, this.fieldValues);

  Class get classNode => classReference.asClass;

  @override
  void visitChildren(Visitor v) {
    classReference.asClass.acceptReference(v);
    visitList(typeArguments, v);
    for (final Reference reference in fieldValues.keys) {
      reference.asField.acceptReference(v);
    }
    for (final Constant constant in fieldValues.values) {
      constant.acceptReference(v);
    }
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitInstanceConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitInstanceConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitInstanceConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitInstanceConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('const ');
    printer.writeClassName(classReference);
    printer.writeTypeArguments(typeArguments);
    printer.write('{');
    String comma = '';
    fieldValues.forEach((Reference fieldRef, Constant constant) {
      printer.write(comma);
      printer.writeMemberName(fieldRef);
      printer.write(': ');
      printer.writeConstant(constant);
      comma = ', ';
    });
    printer.write('}');
  }

  @override
  String toString() => 'InstanceConstant(${toStringInternal()})';

  @override
  late final int hashCode = _Hash.combine2Finish(classReference.hashCode,
      listHashCode(typeArguments), _Hash.combineMapHashUnordered(fieldValues));

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is InstanceConstant &&
            other.classReference == classReference &&
            listEquals(other.typeArguments, typeArguments) &&
            mapEquals(other.fieldValues, fieldValues));
  }

  @override
  DartType getType(StaticTypeContext context) =>
      new InterfaceType(classNode, context.nonNullable, typeArguments);
}

class InstantiationConstant extends Constant {
  final Constant tearOffConstant;
  final List<DartType> types;

  InstantiationConstant(this.tearOffConstant, this.types);

  @override
  void visitChildren(Visitor v) {
    tearOffConstant.acceptReference(v);
    visitList(types, v);
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitInstantiationConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitInstantiationConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitInstantiationConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitInstantiationConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeConstant(tearOffConstant);
    printer.writeTypeArguments(types);
  }

  @override
  String toString() => 'InstantiationConstant(${toStringInternal()})';

  @override
  int get hashCode => _Hash.combineFinish(
      tearOffConstant.hashCode, _Hash.combineListHash(types));

  @override
  bool operator ==(Object other) {
    return other is InstantiationConstant &&
        other.tearOffConstant == tearOffConstant &&
        listEquals(other.types, types);
  }

  @override
  DartType getType(StaticTypeContext context) {
    final FunctionType type = tearOffConstant.getType(context) as FunctionType;
    return FunctionTypeInstantiator.instantiate(type, types);
  }
}

abstract class TearOffConstant implements Constant {
  Reference get targetReference;
  Member get target;
  FunctionNode get function;
}

class StaticTearOffConstant extends Constant implements TearOffConstant {
  @override
  final Reference targetReference;

  StaticTearOffConstant(Procedure target)
      : assert(target.isStatic),
        assert(target.kind == ProcedureKind.Method,
            "Unexpected static tear off target: $target"),
        targetReference = target.reference;

  StaticTearOffConstant.byReference(this.targetReference);

  @override
  Procedure get target => targetReference.asProcedure;

  @override
  FunctionNode get function => target.function;

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitStaticTearOffConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitStaticTearOffConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitStaticTearOffConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitStaticTearOffConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
  }

  @override
  String toString() => 'StaticTearOffConstant(${toStringInternal()})';

  @override
  int get hashCode => targetReference.hashCode;

  @override
  bool operator ==(Object other) {
    return other is StaticTearOffConstant &&
        other.targetReference == targetReference;
  }

  @override
  FunctionType getType(StaticTypeContext context) {
    return target.function.computeFunctionType(context.nonNullable);
  }
}

class ConstructorTearOffConstant extends Constant implements TearOffConstant {
  @override
  final Reference targetReference;

  ConstructorTearOffConstant(Member target)
      : assert(
            target is Constructor || (target is Procedure && target.isFactory),
            "Unexpected constructor tear off target: $target"),
        this.targetReference = getNonNullableMemberReferenceGetter(target);

  ConstructorTearOffConstant.byReference(this.targetReference);

  @override
  Member get target => targetReference.asMember;

  @override
  FunctionNode get function => target.function!;

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitConstructorTearOffConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitConstructorTearOffConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitConstructorTearOffConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitConstructorTearOffConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
  }

  @override
  String toString() => 'ConstructorTearOffConstant(${toStringInternal()})';

  @override
  int get hashCode => targetReference.hashCode;

  @override
  bool operator ==(Object other) {
    return other is ConstructorTearOffConstant &&
        other.targetReference == targetReference;
  }

  @override
  FunctionType getType(StaticTypeContext context) {
    return function.computeFunctionType(context.nonNullable);
  }
}

class RedirectingFactoryTearOffConstant extends Constant
    implements TearOffConstant {
  @override
  final Reference targetReference;

  RedirectingFactoryTearOffConstant(Procedure target)
      : assert(target.isRedirectingFactory),
        this.targetReference = getNonNullableMemberReferenceGetter(target);

  RedirectingFactoryTearOffConstant.byReference(this.targetReference);

  @override
  Procedure get target => targetReference.asProcedure;

  @override
  FunctionNode get function => target.function;

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
  }

  @override
  R accept<R>(ConstantVisitor<R> v) =>
      v.visitRedirectingFactoryTearOffConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitRedirectingFactoryTearOffConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitRedirectingFactoryTearOffConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitRedirectingFactoryTearOffConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
  }

  @override
  String toString() =>
      'RedirectingFactoryTearOffConstant(${toStringInternal()})';

  @override
  int get hashCode => targetReference.hashCode;

  @override
  bool operator ==(Object other) {
    return other is RedirectingFactoryTearOffConstant &&
        other.targetReference == targetReference;
  }

  @override
  FunctionType getType(StaticTypeContext context) {
    return function.computeFunctionType(context.nonNullable);
  }
}

class TypedefTearOffConstant extends Constant {
  final List<StructuralParameter> parameters;
  final TearOffConstant tearOffConstant;
  final List<DartType> types;

  @override
  late final int hashCode = _computeHashCode();

  TypedefTearOffConstant(this.parameters, this.tearOffConstant, this.types);

  @override
  void visitChildren(Visitor v) {
    visitList(parameters, v);
    tearOffConstant.acceptReference(v);
    visitList(types, v);
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitTypedefTearOffConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitTypedefTearOffConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitTypedefTearOffConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitTypedefTearOffConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeStructuralParameters(parameters);
    printer.writeConstant(tearOffConstant);
    printer.writeTypeArguments(types);
  }

  @override
  String toString() => 'TypedefTearOffConstant(${toStringInternal()})';

  @override
  bool operator ==(Object other) {
    if (other is! TypedefTearOffConstant) return false;
    if (other.tearOffConstant != tearOffConstant) return false;
    if (other.parameters.length != parameters.length) return false;
    if (parameters.isNotEmpty) {
      Assumptions assumptions = new Assumptions();
      for (int index = 0; index < parameters.length; index++) {
        assumptions.assumeStructuralParameter(
            parameters[index], other.parameters[index]);
      }
      for (int index = 0; index < parameters.length; index++) {
        if (!parameters[index]
            .bound
            .equals(other.parameters[index].bound, assumptions)) {
          return false;
        }
      }
      for (int i = 0; i < types.length; ++i) {
        if (!types[i].equals(other.types[i], assumptions)) {
          return false;
        }
      }
    }
    return true;
  }

  int _computeHashCode() {
    int hash = 1237;
    for (int i = 0; i < parameters.length; ++i) {
      StructuralParameter parameter = parameters[i];
      hash = 0x3fffffff & (hash * 31 + parameter.bound.hashCode);
    }
    for (int i = 0; i < types.length; ++i) {
      hash = 0x3fffffff & (hash * 31 + types[i].hashCode);
    }
    hash = 0x3fffffff & (hash * 31 + tearOffConstant.hashCode);
    return hash;
  }

  @override
  DartType getType(StaticTypeContext context) {
    FunctionType type = tearOffConstant.getType(context) as FunctionType;
    FreshStructuralParameters freshStructuralParameters =
        getFreshStructuralParameters(parameters);
    type = freshStructuralParameters.substitute(
        FunctionTypeInstantiator.instantiate(type, types)) as FunctionType;
    return new FunctionType(
        type.positionalParameters, type.returnType, type.declaredNullability,
        namedParameters: type.namedParameters,
        typeParameters: freshStructuralParameters.freshTypeParameters,
        requiredParameterCount: type.requiredParameterCount);
  }
}

class TypeLiteralConstant extends Constant {
  final DartType type;

  TypeLiteralConstant(this.type);

  @override
  void visitChildren(Visitor v) {
    type.accept(v);
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitTypeLiteralConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitTypeLiteralConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitTypeLiteralConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitTypeLiteralConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeType(type);
  }

  @override
  String toString() => 'TypeLiteralConstant(${toStringInternal()})';

  @override
  int get hashCode => type.hashCode;

  @override
  bool operator ==(Object other) {
    return other is TypeLiteralConstant && other.type == type;
  }

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.typeRawType(context.nonNullable);
}

class UnevaluatedConstant extends Constant {
  final Expression expression;

  UnevaluatedConstant(this.expression) {
    expression.parent = null;
  }

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitUnevaluatedConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitUnevaluatedConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitUnevaluatedConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitUnevaluatedConstantReference(this, arg);

  @override
  DartType getType(StaticTypeContext context) =>
      expression.getStaticType(context);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('unevaluated{');
    printer.writeExpression(expression);
    printer.write('}');
  }

  @override
  String toString() {
    return "UnevaluatedConstant(${toStringInternal()})";
  }

  @override
  int get hashCode => expression.hashCode;

  @override
  bool operator ==(Object other) {
    return other is UnevaluatedConstant && other.expression == expression;
  }
}
