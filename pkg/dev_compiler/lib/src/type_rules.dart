library ddc.src.type_rules;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

import 'type_walker.dart';
import 'static_info.dart';

abstract class TypeRules {
  final TypeProvider provider;

  TypeRules(TypeProvider this.provider);

  bool isSubTypeOf(DartType t1, DartType t2);
  bool isAssignable(DartType t1, DartType t2);

  bool isPrimitive(DartType t) => false;
  bool isBoxable(DartType t) => false;
  DartType boxedType(DartType t) => throw "Unreachable";

  TypeMismatch checkAssignment(Expression expr, DartType t);

  void setCompilationUnit(CompilationUnit unit) {}

  DartType getStaticType(Expression expr) => expr.staticType;

  DartType mapGenericType(DartType type);
  DartType elementType(Element e);
}

class DartRules extends TypeRules {
  DartRules(TypeProvider provider) : super(provider);

  bool isSubTypeOf(DartType t1, DartType t2) {
    return t1.isSubtypeOf(t2);
  }

  bool isAssignable(DartType t1, DartType t2) {
    return t1.isAssignableTo(t2);
  }

  TypeMismatch checkAssignment(Expression expr, DartType toType) {
    final fromType = getStaticType(expr);
    if (!isAssignable(fromType, toType)) {
      return new StaticTypeError(this, expr, toType);
    }
    return null;
  }

  DartType mapGenericType(DartType type) => type;

  DartType elementType(Element e) {
    return (e as dynamic).type;
  }
}

class RestrictedRules extends TypeRules {
  // If true, num is treated as a synonym for double.
  // If false, num is always boxed.
  static const bool primitiveNum = false;
  RestrictedTypeWalker _typeWalker = null;
  LibraryElement _current = null;

  RestrictedRules(TypeProvider provider) : super(provider);

  void setCompilationUnit(CompilationUnit unit) {
    LibraryElement lib = unit.element.enclosingElement;
    if (lib != _current) {
      _current = lib;
      _typeWalker = new RestrictedTypeWalker(provider, _current);
      unit.visitChildren(_typeWalker);
    }
  }

  // FIXME: Don't use Dart's static type propagation rules.
  DartType getStaticType(Expression expr) {
    return _typeWalker.getStaticType(expr);
    //return super.getStaticType(expr);
  }

  bool isDynamic(DartType t) {
    // Erasure
    if (t is TypeParameterType) return true;
    if (t.isDartCoreFunction) return true;
    return t.isDynamic;
  }

  bool canBeBoxedTo(DartType primitiveType, DartType boxedType) {
    assert(isPrimitive(primitiveType));
    // Any primitive can be boxed to Object or dynamic.
    if (boxedType.isObject ||
        boxedType.isDynamic ||
        boxedType is TypeParameterType) {
      return true;
    }
    // True iff a location with this type may be assigned a boxed
    // int or double.
    if (primitiveType !=
        provider.boolType && !primitiveNum && boxedType.name == "num") {
      return true;
    }
    return false;
  }

  bool isPrimitive(DartType t) {
    // FIXME: Handle VoidType here?
    if (t.isVoid) return true;
    if (t == provider.intType ||
        t == provider.doubleType ||
        t == provider.boolType) return true;
    if (primitiveNum && t.name == "num") return true;
    return false;
  }

  bool isBoxable(DartType t) {
    return isPrimitive(t) && !t.isVoid;
  }

  DartType boxedType(DartType t) {
    assert(isBoxable(t));
    if (t == provider.boolType) return provider.objectType;
    if (t == provider.intType || t == provider.doubleType) {
      return primitiveNum ? provider.objectType : provider.numType;
    }
    if (primitiveNum && t == provider.numType) return provider.objectType;
    assert(false);
    return null;
  }

  bool isPrimitiveEquals(DartType t1, DartType t2) {
    assert(isPrimitive(t1) || isPrimitive(t2));
    if (primitiveNum) {
      t1 = (t1.name == "num") ? provider.doubleType : t1;
      t2 = (t2.name == "num") ? provider.doubleType : t2;
    }
    return t1 == t2;
  }

  bool isWrappableFunctionType(FunctionType f1, FunctionType f2) {
    // Can f1 be wrapped into an f2?
    assert(!isFunctionSubTypeOf(f1, f2));
    return isFunctionSubTypeOf(f1, f2, true);
  }

  bool canAutoConvertTo(DartType t1, DartType t2) {
    // TODO(vsm): Factor out common logic with error reporting below.
    if (isPrimitive(t2) && canBeBoxedTo(t2, t1)) {
      // Unbox
      return true;
    } else if (isDynamic(t1)) {
      // Type check
      return true;
    } else if (isPrimitive(t1) && canBeBoxedTo(t1, t2)) {
      // Box
      return true;
    } else if (isSubTypeOf(t2, t1)) {
      // Down cast
      // return true;
      return false;
    } else if (isPrimitive(t1) && isPrimitive(t2)) {
      // Primitive conversion
      return true;
    } else if (t2.isVoid) {
      // Ignore the value.
      return true;
    }
    return false;
  }

  bool isFunctionSubTypeOf(
      FunctionType f1, FunctionType f2, [bool wrap = false]) {
    final params1 = f1.parameters;
    final params2 = f2.parameters;
    final ret1 = f1.returnType;
    final ret2 = f2.returnType;

    // TODO(vsm): Factor this out.  If ret1 can be auto-converted to ret2:
    //  - primitive conversion
    //  - box
    //  - unbox
    //  - cast to dynamic
    //  - cast from dynamic
    // TODO(vsm): Emit a warning when we require a wrapped function
    if (!isSubTypeOf(ret1, ret2) && !(wrap && canAutoConvertTo(ret1, ret2))) {
      // Covariant return types.
      return false;
    }

    if (params1.length < params2.length) {
      return false;
    }

    for (int i = 0; i < params2.length; ++i) {
      ParameterElement p1 = params1[i];
      ParameterElement p2 = params2[i];

      // Contravariant parameter types.
      if (!isSubTypeOf(
          p2.type, p1.type) && !(wrap && canAutoConvertTo(p2.type, p1.type))) {
        return false;
      }

      // If the base param is optional, the sub param must be optional:
      // - either neither are named or
      // - both are named with the same name
      // If the base param is required, the sub may be optional, but not named.
      if (p2.parameterKind != ParameterKind.REQUIRED) {
        if (p1.parameterKind == ParameterKind.REQUIRED) return false;
        if (p2.parameterKind == ParameterKind.NAMED &&
            (p1.parameterKind != ParameterKind.NAMED || p1.name != p2.name)) {
          return false;
        }
      } else {
        if (p1.parameterKind == ParameterKind.NAMED) return false;
      }
    }
    return true;
  }

  bool isInterfaceSubTypeOf(InterfaceType i1, InterfaceType i2) {
    // FIXME: Verify this!
    // Note: this essentially applies erasure on generics
    // instead of Dart's covariance.

    if (i1 == i2) return true;

    // Erasure!
    if (i1.element == i2.element) return true;

    if (i1 == provider.objectType) return false;

    if (isInterfaceSubTypeOf(i1.superclass, i2)) return true;

    for (final parent in i1.interfaces) {
      if (isInterfaceSubTypeOf(parent, i2)) return true;
    }

    for (final parent in i1.mixins) {
      if (isInterfaceSubTypeOf(parent, i2)) return true;
    }

    return false;
  }

  bool isSubTypeOf(DartType t1, DartType t2) {
    // Primitives are standalone types.  Unless boxed, they do not subtype
    // Object and are not subtyped by dynamic.
    if (isPrimitive(t1) || isPrimitive(t2)) return isPrimitiveEquals(t1, t2);

    if (t1 is TypeParameterType) t1 = provider.dynamicType;
    if (t2 is TypeParameterType) t2 = provider.dynamicType;

    if (t1 == t2) return true;

    // Null can be assigned to anything else.
    // FIXME: Can this be anything besides null?
    if (t1.isBottom) return true;

    // Trivially true for non-primitives.
    if (t2 == provider.objectType) return true;

    // Trivially false.
    if (t1 == provider.objectType && t2 != provider.dynamicType) return false;

    // How do we handle dynamic?  In Dart, dynamic subtypes everything.
    // This is somewhat counterintuitive - subtyping usually narrows.
    // Here we treat dynamic essentially as Object.
    if (isDynamic(t1)) return false;
    if (isDynamic(t2)) return true;

    // "Traditional" name-based subtype check.
    // FIXME: What happens with classes that implement Function?
    // Are typedefs handled correctly?
    if (t1 is InterfaceType && t2 is InterfaceType) {
      if (isInterfaceSubTypeOf(t1, t2)) {
        return true;
      }
    }

    if (t1 is! FunctionType || t2 is! FunctionType) return false;

    // Functions
    // Note: it appears under the hood all Dart functions map to a class /
    // hidden type that:
    //  (a) subtypes Object (an internal _FunctionImpl in the VM)
    //  (b) implements Function
    //  (c) provides standard Object members (hashCode, toString)
    //  (d) contains private members (corresponding to _FunctionImpl?)
    //  (e) provides a call method to handle the actual function invocation
    //
    // The standard Dart subtyping rules are structural in nature.  I.e.,
    // bivariant on arguments and return type.
    //
    // The below tries for a more traditional subtyping rule:
    // - covariant on return type
    // - contravariant on parameters
    // - 'sensible' (?) rules on optional and/or named params
    // but doesn't properly mix with class subtyping.  I suspect Java 8 lambdas
    // essentially map to dynamic (and rely on invokedynamic) due to similar
    // issues.
    return isFunctionSubTypeOf(t1 as FunctionType, t2 as FunctionType);
  }

  bool isAssignable(DartType t1, DartType t2) {
    return isSubTypeOf(t1, t2);
  }

  TypeMismatch checkAssignment(Expression expr, DartType type) {
    final exprType = getStaticType(expr);
    if (!isAssignable(exprType, type)) {
      if (isPrimitive(type) && canBeBoxedTo(type, exprType)) {
        return new Unbox(this, expr, type);
      } else if (isDynamic(exprType)) {
        return new DownCast(this, expr, type);
      } else if (isPrimitive(exprType) && canBeBoxedTo(exprType, type)) {
        return new Box(this, expr);
      } else if (isSubTypeOf(type, exprType)) {
        return new DownCast(this, expr, type);
      } else if (isPrimitive(exprType) && isPrimitive(type)) {
        // TODO(vsm): Should this be restricted?
        assert(type == provider.doubleType);
        return new NumericConversion(this, expr);
      } else {
        if (exprType is FunctionType &&
            type is FunctionType &&
            isWrappableFunctionType(exprType, type)) {
          return new ClosureWrap(this, expr, type);
        } else {
          return new StaticTypeError(this, expr, type);
        }
      }
    }
    return null;
  }

  DartType mapGenericType(DartType type) {
    return _typeWalker.dynamize(type);
  }

  DartType elementType(Element e) {
    return _typeWalker.baseElementType(e);
  }
}
