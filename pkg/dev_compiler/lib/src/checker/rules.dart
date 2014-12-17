library ddc.src.checker.rules;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

import 'package:ddc/src/info.dart';
import 'package:ddc/src/utils.dart' show logCheckerMessage;

abstract class TypeRules {
  final TypeProvider provider;
  LibraryInfo currentLibraryInfo = null;

  TypeRules(TypeProvider this.provider);

  bool isSubTypeOf(DartType t1, DartType t2);
  bool isAssignable(DartType t1, DartType t2);

  bool isGroundType(DartType t) => true;

  bool isBoolType(DartType t) => t == provider.boolType;
  bool isDoubleType(DartType t) => t == provider.doubleType;
  bool isIntType(DartType t) => t == provider.intType;
  bool isNumType(DartType t) => t.name == "num";

  StaticInfo checkAssignment(Expression expr, DartType t);

  DartType getStaticType(Expression expr) => expr.staticType;

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

  StaticInfo checkAssignment(Expression expr, DartType toType) {
    final fromType = getStaticType(expr);
    if (!isAssignable(fromType, toType)) {
      return new StaticTypeError(this, expr, toType);
    }
    return null;
  }

  DartType elementType(Element e) {
    return (e as dynamic).type;
  }
}

class RestrictedRules extends TypeRules {

  RestrictedRules(TypeProvider provider) : super(provider);

  DartType getStaticType(Expression expr) {
    var type = expr.staticType;
    if (type != null) return type;

    var node = currentLibraryInfo.nodeInfo
        .putIfAbsent(expr, () => new SemanticNode(expr));
    var info = new MissingTypeError(expr);
    node.messages.add(info);
    logCheckerMessage(info);
    return provider.dynamicType;
  }

  // TODO(leafp): Revisit this.
  bool isGroundType(DartType t) {
    if (t is FunctionType) return false;
    if (t is TypeParameterType) return false;
    if (t.isDynamic) return true;

    // t must be an InterfacetType.
    var typeArguments = (t as InterfaceType).typeArguments;
    for (var typeArgument in typeArguments) {
      if (!typeArgument.isDynamic) return false;
    }

    return true;
  }

  bool isFunctionSubTypeOf(FunctionType f1, FunctionType f2) {
    final params1 = f1.parameters;
    final params2 = f2.parameters;
    final ret1 = f1.returnType;
    final ret2 = f2.returnType;

    // A -> B <: C -> D if C <: A and
    // either D is void or B <: D
    if (!ret2.isVoid && !isSubTypeOf(ret1, ret2)) return false;

    if (params1.length < params2.length) return false;

    for (int i = 0; i < params2.length; ++i) {
      ParameterElement p1 = params1[i];
      ParameterElement p2 = params2[i];

      // Contravariant parameter types.
      if (!isSubTypeOf(p2.type, p1.type)) return false;

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

  bool _isInterfaceSubTypeOf(InterfaceType i1, InterfaceType i2) {
    if (i1 == i2) return true;

    if (i1.element == i2.element) {
      List<DartType> tArgs1 = i1.typeArguments;
      List<DartType> tArgs2 = i2.typeArguments;

      // TODO(leafp): Verify that this is always true
      // Do raw types get filled in?
      assert(tArgs1.length == tArgs2.length);

      for (int i = 0; i < tArgs1.length; i++) {
        DartType t1 = tArgs1[i];
        DartType t2 = tArgs2[i];
        if ((t1 != t2) && !t2.isDynamic) return false;
      }
      return true;
    }

    if (i2.isDartCoreFunction) {
      if (i1.element.getMethod("call") != null) return true;
    }

    if (i1 == provider.objectType) return false;

    if (_isInterfaceSubTypeOf(i1.superclass, i2)) return true;

    for (final parent in i1.interfaces) {
      if (_isInterfaceSubTypeOf(parent, i2)) return true;
    }

    for (final parent in i1.mixins) {
      if (_isInterfaceSubTypeOf(parent, i2)) return true;
    }

    return false;
  }

  bool isSubTypeOf(DartType t1, DartType t2) {

    if (t1 == t2) return true;

    // Null can be assigned to anything else.
    // FIXME: Can this be anything besides null?
    if (t1.isBottom) return true;
    if (t2.isBottom) return false;

    if (t2.isDynamic) return true;
    if (t1.isDynamic) return false;

    // Trivially true for non-primitives.
    if (t2 == provider.objectType) return true;
    if (t1 == provider.objectType) return false;

    // S <: T where S is a type variable
    //  T is not dynamic or object (handled above)
    //  S != T (handled above)
    //  So only true if bound of S is S' and
    //  S' <: T
    if (t1 is TypeParameterType) {
      DartType bound = t1.element.bound;
      if (bound == null) return false;
      return isSubTypeOf(bound, t2);
    }

    if (t2.isDartCoreFunction) {
      if (t1 is FunctionType) return true;
      if (t1.element is ClassElement) {
        if ((t1.element as ClassElement).getMethod("call") != null) return true;
      }
    }

    // "Traditional" name-based subtype check.
    if (t1 is InterfaceType && t2 is InterfaceType) {
      return _isInterfaceSubTypeOf(t1 as InterfaceType, t2 as InterfaceType);
    }

    if (t1 is! FunctionType && t2 is! FunctionType) return false;

    if (t1 is InterfaceType && t2 is FunctionType) {
      // TODO(leafp): check t1 for a call method of the appropriate type
      return false;
    }

    if (t1 is FunctionType && t2 is InterfaceType) {
      // TODO(leafp): check t2 for a call method of the appropriate type
      return false;
    }

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

  StaticInfo checkAssignment(Expression expr, DartType toT) {
    final fromT = getStaticType(expr);

    // fromT <: toT, no coercion needed
    if (isSubTypeOf(fromT, toT)) return null;

    // TODO(leafp): This is very simplistic.  Revisit.
    // toT </: fromT, reject for now
    if (!isSubTypeOf(toT, fromT)) return new StaticTypeError(this, expr, toT);

    // Downcasting from dynamic to object always succeeds,
    // no coercion needed.
    if (toT == provider.objectType) return null;

    // For now, we always wrap closures.
    if (fromT is FunctionType && toT is FunctionType) {
      return new ClosureWrap(this, expr, toT);
    }

    // Everything else we just do a downcast.
    return new DownCast(this, expr, toT);
  }

  DartType elementType(Element e) {
    return (e as dynamic).type;
  }
}
