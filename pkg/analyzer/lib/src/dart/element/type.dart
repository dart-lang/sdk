// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.element.type;

import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine, AnalysisException;
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/scanner.dart' show Keyword;
import 'package:analyzer/src/generated/utilities_dart.dart';

/**
 * A [Type] that represents the type 'bottom'.
 */
class BottomTypeImpl extends TypeImpl {
  /**
   * The unique instance of this class.
   */
  static BottomTypeImpl _INSTANCE = new BottomTypeImpl._();

  /**
   * Return the unique instance of this class.
   */
  static BottomTypeImpl get instance => _INSTANCE;

  /**
   * Prevent the creation of instances of this class.
   */
  BottomTypeImpl._() : super(null, "<bottom>");

  @override
  int get hashCode => 0;

  @override
  bool get isBottom => true;

  @override
  bool operator ==(Object object) => identical(object, this);

  @override
  bool isMoreSpecificThan(DartType type,
          [bool withDynamic = false, Set<Element> visitedElements]) =>
      true;

  @override
  bool isSubtypeOf(DartType type) => true;

  @override
  bool isSupertypeOf(DartType type) => false;

  @override
  TypeImpl pruned(List<FunctionTypeAliasElement> prune) => this;

  @override
  BottomTypeImpl substitute2(
          List<DartType> argumentTypes, List<DartType> parameterTypes,
          [List<FunctionTypeAliasElement> prune]) =>
      this;
}

/**
 * Type created internally if a circular reference is ever detected.  Behaves
 * like `dynamic`, except that when converted to a string it is displayed as
 * `...`.
 */
class CircularTypeImpl extends DynamicTypeImpl {
  CircularTypeImpl() : super._circular();

  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object object) => object is CircularTypeImpl;

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write('...');
  }

  @override
  TypeImpl pruned(List<FunctionTypeAliasElement> prune) => this;
}

/**
 * The [Type] representing the type `dynamic`.
 */
class DynamicTypeImpl extends TypeImpl {
  /**
   * The unique instance of this class.
   */
  static DynamicTypeImpl _INSTANCE = new DynamicTypeImpl._();

  /**
   * Return the unique instance of this class.
   */
  static DynamicTypeImpl get instance => _INSTANCE;

  /**
   * Prevent the creation of instances of this class.
   */
  DynamicTypeImpl._()
      : super(new DynamicElementImpl(), Keyword.DYNAMIC.syntax) {
    (element as DynamicElementImpl).type = this;
  }

  /**
   * Constructor used by [CircularTypeImpl].
   */
  DynamicTypeImpl._circular()
      : super(_INSTANCE.element, Keyword.DYNAMIC.syntax);

  @override
  int get hashCode => 1;

  @override
  bool get isDynamic => true;

  @override
  bool operator ==(Object object) => identical(object, this);

  @override
  bool isMoreSpecificThan(DartType type,
      [bool withDynamic = false, Set<Element> visitedElements]) {
    // T is S
    if (identical(this, type)) {
      return true;
    }
    // else
    return withDynamic;
  }

  @override
  bool isSubtypeOf(DartType type) => true;

  @override
  bool isSupertypeOf(DartType type) => true;

  @override
  TypeImpl pruned(List<FunctionTypeAliasElement> prune) => this;

  @override
  DartType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]) {
    int length = parameterTypes.length;
    for (int i = 0; i < length; i++) {
      if (parameterTypes[i] == this) {
        return argumentTypes[i];
      }
    }
    return this;
  }
}

/**
 * The type of a function, method, constructor, getter, or setter.
 */
class FunctionTypeImpl extends TypeImpl implements FunctionType {
  /**
   * The list of [typeArguments].
   */
  List<DartType> _typeArguments;

  /**
   * The list of [typeParameters].
   */
  List<TypeParameterElement> _typeParameters;

  /**
   * The list of [boundTypeParameters].
   */
  List<TypeParameterElement> _boundTypeParameters;

  /**
   * The set of typedefs which should not be expanded when exploring this type,
   * to avoid creating infinite types in response to self-referential typedefs.
   */
  final List<FunctionTypeAliasElement> prunedTypedefs;

  /**
   * Initialize a newly created function type to be declared by the given
   * [element], and also initialize [typeArguments] to match the
   * [typeParameters], which permits later substitution.
   */
  FunctionTypeImpl(ExecutableElement element,
      [List<FunctionTypeAliasElement> prunedTypedefs])
      : this._(element, null, prunedTypedefs, null, null, null);

  /**
   * Initialize a newly created function type to be declared by the given
   * [element], with the given [name].
   */
  FunctionTypeImpl.elementWithName(Element element, String name)
      : prunedTypedefs = null,
        super(element, name);

  /**
   * Initialize a newly created function type to be declared by the given
   * [element].
   */
  FunctionTypeImpl.forTypedef(FunctionTypeAliasElement element,
      [List<FunctionTypeAliasElement> prunedTypedefs])
      : this._(element, element?.name, prunedTypedefs, null, null, null);

  /**
   * Private constructor.
   */
  FunctionTypeImpl._(
      TypeParameterizedElement element,
      String name,
      this.prunedTypedefs,
      List<DartType> typeArguments,
      List<TypeParameterElement> typeParameters,
      List<TypeParameterElement> boundTypeParameters)
      : super(element, name) {
    _boundTypeParameters = boundTypeParameters ??
        element?.typeParameters ??
        TypeParameterElement.EMPTY_LIST;

    if (typeParameters == null) {
      // Combine the generic type variables from all enclosing contexts, except
      // for this generic function's type variables. Those variables are
      // tracked in [boundTypeParameters].
      typeParameters = <TypeParameterElement>[];
      Element e = element?.enclosingElement;
      while (e != null) {
        if (e is TypeParameterizedElement) {
          typeParameters.addAll((e as TypeParameterizedElement).typeParameters);
        }
        e = e.enclosingElement;
      }
    }
    _typeParameters = typeParameters;

    if (typeArguments == null) {
      // TODO(jmesserly): reuse TypeParameterTypeImpl.getTypes once we can
      // make it generic, which will allow it to return List<DartType> instead
      // of List<TypeParameterType>.
      if (typeParameters.isEmpty) {
        typeArguments = DartType.EMPTY_LIST;
      } else {
        typeArguments = new List<DartType>.from(
            typeParameters.map((t) => t.type),
            growable: false);
      }
    }
    _typeArguments = typeArguments;
  }

  /**
   * Return the base parameter elements of this function element.
   */
  List<ParameterElement> get baseParameters => element.parameters;

  /**
   * Return the return type defined by this function's element.
   */
  DartType get baseReturnType => element.returnType;

  @override
  List<TypeParameterElement> get boundTypeParameters => _boundTypeParameters;

  @override
  String get displayName {
    String name = this.name;
    if (name == null || name.length == 0) {
      // Function types have an empty name when they are defined implicitly by
      // either a closure or as part of a parameter declaration.
      List<DartType> normalParameterTypes = this.normalParameterTypes;
      List<DartType> optionalParameterTypes = this.optionalParameterTypes;
      Map<String, DartType> namedParameterTypes = this.namedParameterTypes;
      DartType returnType = this.returnType;
      StringBuffer buffer = new StringBuffer();
      buffer.write("(");
      bool needsComma = false;
      if (normalParameterTypes.length > 0) {
        for (DartType type in normalParameterTypes) {
          if (needsComma) {
            buffer.write(", ");
          } else {
            needsComma = true;
          }
          buffer.write(type.displayName);
        }
      }
      if (optionalParameterTypes.length > 0) {
        if (needsComma) {
          buffer.write(", ");
          needsComma = false;
        }
        buffer.write("[");
        for (DartType type in optionalParameterTypes) {
          if (needsComma) {
            buffer.write(", ");
          } else {
            needsComma = true;
          }
          buffer.write(type.displayName);
        }
        buffer.write("]");
        needsComma = true;
      }
      if (namedParameterTypes.length > 0) {
        if (needsComma) {
          buffer.write(", ");
          needsComma = false;
        }
        buffer.write("{");
        namedParameterTypes.forEach((String name, DartType type) {
          if (needsComma) {
            buffer.write(", ");
          } else {
            needsComma = true;
          }
          buffer.write(name);
          buffer.write(": ");
          buffer.write(type.displayName);
        });
        buffer.write("}");
        needsComma = true;
      }
      buffer.write(")");
      buffer.write(ElementImpl.RIGHT_ARROW);
      if (returnType == null) {
        buffer.write("null");
      } else {
        buffer.write(returnType.displayName);
      }
      name = buffer.toString();
    }
    return name;
  }

  @override
  FunctionTypedElement get element => super.element;

  @override
  int get hashCode {
    if (element == null) {
      return 0;
    }
    // Reference the arrays of parameters
    List<DartType> normalParameterTypes = this.normalParameterTypes;
    List<DartType> optionalParameterTypes = this.optionalParameterTypes;
    Iterable<DartType> namedParameterTypes = this.namedParameterTypes.values;
    // Generate the hashCode
    int code = (returnType as TypeImpl).hashCode;
    for (int i = 0; i < normalParameterTypes.length; i++) {
      code = (code << 1) + (normalParameterTypes[i] as TypeImpl).hashCode;
    }
    for (int i = 0; i < optionalParameterTypes.length; i++) {
      code = (code << 1) + (optionalParameterTypes[i] as TypeImpl).hashCode;
    }
    for (DartType type in namedParameterTypes) {
      code = (code << 1) + (type as TypeImpl).hashCode;
    }
    return code;
  }

  /**
   * The type arguments that were used to instantiate this function type, if
   * any, otherwise this will return an empty list.
   *
   * Given a function type `f`:
   *
   *     f == f.originalFunction.instantiate(f.instantiatedTypeArguments)
   *
   * Will always hold.
   */
  List<DartType> get instantiatedTypeArguments {
    int typeParameterCount = element.type.boundTypeParameters.length;
    if (typeParameterCount == 0) {
      return DartType.EMPTY_LIST;
    }
    // The substituted types at the end should be our bound type parameters.
    int skipCount = typeArguments.length - typeParameterCount;
    return new List<DartType>.from(typeArguments.skip(skipCount));
  }

  @override
  Map<String, DartType> get namedParameterTypes {
    LinkedHashMap<String, DartType> namedParameterTypes =
        new LinkedHashMap<String, DartType>();
    List<ParameterElement> parameters = baseParameters;
    if (parameters.length == 0) {
      return namedParameterTypes;
    }
    List<DartType> typeParameters =
        TypeParameterTypeImpl.getTypes(this.typeParameters);
    for (ParameterElement parameter in parameters) {
      if (parameter.parameterKind == ParameterKind.NAMED) {
        DartType type = parameter.type;
        if (typeArguments.length != 0 &&
            typeArguments.length == typeParameters.length) {
          type = (type as TypeImpl)
              .substitute2(typeArguments, typeParameters, newPrune);
        } else {
          type = (type as TypeImpl).pruned(newPrune);
        }
        namedParameterTypes[parameter.name] = type;
      }
    }
    return namedParameterTypes;
  }

  /**
   * Determine the new set of typedefs which should be pruned when expanding
   * this function type.
   */
  List<FunctionTypeAliasElement> get newPrune {
    Element element = this.element;
    if (element is FunctionTypeAliasElement && !element.isSynthetic) {
      // This typedef should be pruned, along with anything that was previously
      // pruned.
      if (prunedTypedefs == null) {
        return <FunctionTypeAliasElement>[element];
      } else {
        return new List<FunctionTypeAliasElement>.from(prunedTypedefs)
          ..add(element);
      }
    } else {
      // This is not a typedef, so nothing additional needs to be pruned.
      return prunedTypedefs;
    }
  }

  @override
  List<DartType> get normalParameterTypes {
    List<ParameterElement> parameters = baseParameters;
    if (parameters.length == 0) {
      return DartType.EMPTY_LIST;
    }
    List<DartType> typeParameters =
        TypeParameterTypeImpl.getTypes(this.typeParameters);
    List<DartType> types = new List<DartType>();
    for (ParameterElement parameter in parameters) {
      if (parameter.parameterKind == ParameterKind.REQUIRED) {
        DartType type = parameter.type;
        if (typeArguments.length != 0 &&
            typeArguments.length == typeParameters.length) {
          type = (type as TypeImpl)
              .substitute2(typeArguments, typeParameters, newPrune);
        } else {
          type = (type as TypeImpl).pruned(newPrune);
        }
        types.add(type);
      }
    }
    return types;
  }

  @override
  List<DartType> get optionalParameterTypes {
    List<ParameterElement> parameters = baseParameters;
    if (parameters.length == 0) {
      return DartType.EMPTY_LIST;
    }
    List<DartType> typeParameters =
        TypeParameterTypeImpl.getTypes(this.typeParameters);
    List<DartType> types = new List<DartType>();
    for (ParameterElement parameter in parameters) {
      if (parameter.parameterKind == ParameterKind.POSITIONAL) {
        DartType type = parameter.type;
        if (typeArguments.length != 0 &&
            typeArguments.length == typeParameters.length) {
          type = (type as TypeImpl)
              .substitute2(typeArguments, typeParameters, newPrune);
        } else {
          type = (type as TypeImpl).pruned(newPrune);
        }
        types.add(type);
      }
    }
    return types;
  }

  /**
   * If this is an instantiation of a generic function type, this will get
   * the original function from which it was instantiated.
   *
   * Otherwise, this will return `this`.
   */
  FunctionTypeImpl get originalFunction {
    if (element.type.boundTypeParameters.isEmpty) {
      return this;
    }
    return (element.type as FunctionTypeImpl).substitute2(typeArguments,
        TypeParameterTypeImpl.getTypes(typeParameters), prunedTypedefs);
  }

  @override
  List<ParameterElement> get parameters {
    List<ParameterElement> baseParameters = this.baseParameters;
    // no parameters, quick return
    int parameterCount = baseParameters.length;
    if (parameterCount == 0) {
      return baseParameters;
    }
    // create specialized parameters
    List<ParameterElement> specializedParameters =
        new List<ParameterElement>(parameterCount);
    for (int i = 0; i < parameterCount; i++) {
      specializedParameters[i] = ParameterMember.from(baseParameters[i], this);
    }
    return specializedParameters;
  }

  @override
  DartType get returnType {
    DartType baseReturnType = this.baseReturnType;
    if (baseReturnType == null) {
      // TODO(brianwilkerson) This is a patch. The return type should never be
      // null and we need to understand why it is and fix it.
      return DynamicTypeImpl.instance;
    }
    // If there are no arguments to substitute, or if the arguments size doesn't
    // match the parameter size, return the base return type.
    if (typeArguments.length == 0 ||
        typeArguments.length != typeParameters.length) {
      return (baseReturnType as TypeImpl).pruned(newPrune);
    }
    return (baseReturnType as TypeImpl).substitute2(typeArguments,
        TypeParameterTypeImpl.getTypes(typeParameters), newPrune);
  }

  /**
   * A list containing the actual types of the type arguments.
   */
  List<DartType> get typeArguments => _typeArguments;

  @override
  List<TypeParameterElement> get typeParameters => _typeParameters;

  @override
  bool operator ==(Object object) {
    if (object is! FunctionTypeImpl) {
      return false;
    }
    FunctionTypeImpl otherType = object as FunctionTypeImpl;
    if (boundTypeParameters.length != otherType.boundTypeParameters.length) {
      return false;
    }
    // `<T>T -> T` should be equal to `<U>U -> U`
    // To test this, we instantiate both types with the same (unique) type
    // variables, and see if the result is equal.
    if (boundTypeParameters.isNotEmpty) {
      List<DartType> instantiateTypeArgs = new List<DartType>();
      List<DartType> variablesThis = new List<DartType>();
      List<DartType> variablesOther = new List<DartType>();
      for (int i = 0; i < boundTypeParameters.length; i++) {
        TypeParameterElement pThis = boundTypeParameters[i];
        TypeParameterElement pOther = otherType.boundTypeParameters[i];
        TypeParameterTypeImpl pFresh = new TypeParameterTypeImpl(
            new TypeParameterElementImpl(pThis.name, -1));
        instantiateTypeArgs.add(pFresh);
        variablesThis.add(pThis.type);
        variablesOther.add(pOther.type);
        // Check that the bounds are equal after equating the previous
        // bound variables.
        if (pThis.bound?.substitute2(instantiateTypeArgs, variablesThis) !=
            pOther.bound?.substitute2(instantiateTypeArgs, variablesOther)) {
          return false;
        }
      }
      // After instantiation, they will no longer have boundTypeParameters,
      // so we will continue below.
      return this.instantiate(instantiateTypeArgs) ==
          otherType.instantiate(instantiateTypeArgs);
    }

    return returnType == otherType.returnType &&
        TypeImpl.equalArrays(
            normalParameterTypes, otherType.normalParameterTypes) &&
        TypeImpl.equalArrays(
            optionalParameterTypes, otherType.optionalParameterTypes) &&
        _equals(namedParameterTypes, otherType.namedParameterTypes);
  }

  @override
  void appendTo(StringBuffer buffer) {
    if (boundTypeParameters.isNotEmpty) {
      // To print a type with type variables, first make sure we have unique
      // variable names to print.
      Set<TypeParameterType> freeVariables = new HashSet<TypeParameterType>();
      _freeVariablesInFunctionType(this, freeVariables);

      Set<String> namesToAvoid = new HashSet<String>();
      for (DartType arg in freeVariables) {
        if (arg is TypeParameterType) {
          namesToAvoid.add(arg.displayName);
        }
      }

      List<DartType> instantiateTypeArgs = new List<DartType>();
      List<DartType> variables = new List<DartType>();
      buffer.write("<");
      for (TypeParameterElement e in boundTypeParameters) {
        if (e != boundTypeParameters[0]) {
          buffer.write(",");
        }
        String name = e.name;
        int counter = 0;
        while (!namesToAvoid.add(name)) {
          // Unicode subscript-zero is U+2080, zero is U+0030. Other digits
          // are sequential from there. Thus +0x2050 will get us the subscript.
          String subscript = new String.fromCharCodes(
              counter.toString().codeUnits.map((n) => n + 0x2050));

          name = e.name + subscript;
          counter++;
        }
        TypeParameterTypeImpl t =
            new TypeParameterTypeImpl(new TypeParameterElementImpl(name, -1));
        t.appendTo(buffer);
        instantiateTypeArgs.add(t);
        variables.add(e.type);
        if (e.bound != null) {
          buffer.write(" extends ");
          TypeImpl renamed =
              e.bound.substitute2(instantiateTypeArgs, variables);
          renamed.appendTo(buffer);
        }
      }
      buffer.write(">");

      // Instantiate it and print the resulting type. After instantiation, it
      // will no longer have boundTypeParameters, so we will continue below.
      this.instantiate(instantiateTypeArgs).appendTo(buffer);
      return;
    }

    List<DartType> normalParameterTypes = this.normalParameterTypes;
    List<DartType> optionalParameterTypes = this.optionalParameterTypes;
    Map<String, DartType> namedParameterTypes = this.namedParameterTypes;
    DartType returnType = this.returnType;
    buffer.write("(");
    bool needsComma = false;
    if (normalParameterTypes.isNotEmpty) {
      for (DartType type in normalParameterTypes) {
        if (needsComma) {
          buffer.write(", ");
        } else {
          needsComma = true;
        }
        (type as TypeImpl).appendTo(buffer);
      }
    }
    if (optionalParameterTypes.isNotEmpty) {
      if (needsComma) {
        buffer.write(", ");
        needsComma = false;
      }
      buffer.write("[");
      for (DartType type in optionalParameterTypes) {
        if (needsComma) {
          buffer.write(", ");
        } else {
          needsComma = true;
        }
        (type as TypeImpl).appendTo(buffer);
      }
      buffer.write("]");
      needsComma = true;
    }
    if (namedParameterTypes.isNotEmpty) {
      if (needsComma) {
        buffer.write(", ");
        needsComma = false;
      }
      buffer.write("{");
      namedParameterTypes.forEach((String name, DartType type) {
        if (needsComma) {
          buffer.write(", ");
        } else {
          needsComma = true;
        }
        buffer.write(name);
        buffer.write(": ");
        (type as TypeImpl).appendTo(buffer);
      });
      buffer.write("}");
      needsComma = true;
    }
    buffer.write(")");
    buffer.write(ElementImpl.RIGHT_ARROW);
    if (returnType == null) {
      buffer.write("null");
    } else {
      (returnType as TypeImpl).appendTo(buffer);
    }
  }

  @override
  FunctionTypeImpl instantiate(List<DartType> argumentTypes) {
    if (argumentTypes.length != boundTypeParameters.length) {
      throw new IllegalArgumentException(
          "argumentTypes.length (${argumentTypes.length}) != "
          "boundTypeParameters.length (${boundTypeParameters.length})");
    }
    if (argumentTypes.isEmpty) {
      return this;
    }

    // Given:
    //     {U/T} <S> T -> S
    // Where {U/T} represents the typeArguments (U) and typeParameters (T) list,
    // and <S> represents the boundTypeParameters.
    //
    // Now instantiate([V]), and the result should be:
    //     {U/T, V/S} T -> S.
    List<TypeParameterElement> newTypeParams = typeParameters.toList();
    List<DartType> newTypeArgs = typeArguments.toList();
    newTypeParams.addAll(boundTypeParameters);
    newTypeArgs.addAll(argumentTypes);

    return new FunctionTypeImpl._(element, name, prunedTypedefs, newTypeArgs,
        newTypeParams, TypeParameterElement.EMPTY_LIST);
  }

  @override
  bool isAssignableTo(DartType type) {
    // A function type T may be assigned to a function type S, written T <=> S,
    // iff T <: S.
    return isSubtypeOf(type);
  }

  @override
  bool isMoreSpecificThan(DartType type,
      [bool withDynamic = false, Set<Element> visitedElements]) {
    // Note: visitedElements is only used for breaking recursion in the type
    // hierarchy; we don't use it when recursing into the function type.

    // trivial base cases
    if (type == null) {
      return false;
    } else if (identical(this, type) ||
        type.isDynamic ||
        type.isDartCoreFunction ||
        type.isObject) {
      return true;
    } else if (type is! FunctionType) {
      return false;
    } else if (this == type) {
      return true;
    }
    FunctionType t = this;
    FunctionType s = type as FunctionType;
    List<DartType> tTypes = t.normalParameterTypes;
    List<DartType> tOpTypes = t.optionalParameterTypes;
    List<DartType> sTypes = s.normalParameterTypes;
    List<DartType> sOpTypes = s.optionalParameterTypes;
    // If one function has positional and the other has named parameters,
    // return false.
    if ((sOpTypes.length > 0 && t.namedParameterTypes.length > 0) ||
        (tOpTypes.length > 0 && s.namedParameterTypes.length > 0)) {
      return false;
    }
    // named parameters case
    if (t.namedParameterTypes.length > 0) {
      // check that the number of required parameters are equal, and check that
      // every t_i is more specific than every s_i
      if (t.normalParameterTypes.length != s.normalParameterTypes.length) {
        return false;
      } else if (t.normalParameterTypes.length > 0) {
        for (int i = 0; i < tTypes.length; i++) {
          if (!(tTypes[i] as TypeImpl)
              .isMoreSpecificThan(sTypes[i], withDynamic)) {
            return false;
          }
        }
      }
      Map<String, DartType> namedTypesT = t.namedParameterTypes;
      Map<String, DartType> namedTypesS = s.namedParameterTypes;
      // if k >= m is false, return false: the passed function type has more
      // named parameter types than this
      if (namedTypesT.length < namedTypesS.length) {
        return false;
      }
      // Loop through each element in S verifying that T has a matching
      // parameter name and that the corresponding type is more specific then
      // the type in S.
      for (String keyS in namedTypesS.keys) {
        DartType typeT = namedTypesT[keyS];
        if (typeT == null) {
          return false;
        }
        if (!(typeT as TypeImpl)
            .isMoreSpecificThan(namedTypesS[keyS], withDynamic)) {
          return false;
        }
      }
    } else if (s.namedParameterTypes.length > 0) {
      return false;
    } else {
      // positional parameter case
      int tArgLength = tTypes.length + tOpTypes.length;
      int sArgLength = sTypes.length + sOpTypes.length;
      // Check that the total number of parameters in t is greater than or equal
      // to the number of parameters in s and that the number of required
      // parameters in s is greater than or equal to the number of required
      // parameters in t.
      if (tArgLength < sArgLength || sTypes.length < tTypes.length) {
        return false;
      }
      if (tOpTypes.length == 0 && sOpTypes.length == 0) {
        // No positional arguments, don't copy contents to new array
        for (int i = 0; i < sTypes.length; i++) {
          if (!(tTypes[i] as TypeImpl)
              .isMoreSpecificThan(sTypes[i], withDynamic)) {
            return false;
          }
        }
      } else {
        // Else, we do have positional parameters, copy required and positional
        // parameter types into arrays to do the compare (for loop below).
        List<DartType> tAllTypes = new List<DartType>(sArgLength);
        for (int i = 0; i < tTypes.length; i++) {
          tAllTypes[i] = tTypes[i];
        }
        for (int i = tTypes.length, j = 0; i < sArgLength; i++, j++) {
          tAllTypes[i] = tOpTypes[j];
        }
        List<DartType> sAllTypes = new List<DartType>(sArgLength);
        for (int i = 0; i < sTypes.length; i++) {
          sAllTypes[i] = sTypes[i];
        }
        for (int i = sTypes.length, j = 0; i < sArgLength; i++, j++) {
          sAllTypes[i] = sOpTypes[j];
        }
        for (int i = 0; i < sAllTypes.length; i++) {
          if (!(tAllTypes[i] as TypeImpl)
              .isMoreSpecificThan(sAllTypes[i], withDynamic)) {
            return false;
          }
        }
      }
    }
    DartType tRetType = t.returnType;
    DartType sRetType = s.returnType;
    return sRetType.isVoid ||
        (tRetType as TypeImpl).isMoreSpecificThan(sRetType, withDynamic);
  }

  @override
  bool isSubtypeOf(DartType type) {
    // trivial base cases
    if (type == null) {
      return false;
    } else if (identical(this, type) ||
        type.isDynamic ||
        type.isDartCoreFunction ||
        type.isObject) {
      return true;
    } else if (type is! FunctionType) {
      return false;
    } else if (this == type) {
      return true;
    }
    FunctionType t = this;
    FunctionType s = type as FunctionType;
    List<DartType> tTypes = t.normalParameterTypes;
    List<DartType> tOpTypes = t.optionalParameterTypes;
    List<DartType> sTypes = s.normalParameterTypes;
    List<DartType> sOpTypes = s.optionalParameterTypes;
    // If one function has positional and the other has named parameters,
    // return false.
    if ((sOpTypes.length > 0 && t.namedParameterTypes.length > 0) ||
        (tOpTypes.length > 0 && s.namedParameterTypes.length > 0)) {
      return false;
    }
    // named parameters case
    if (t.namedParameterTypes.length > 0) {
      // check that the number of required parameters are equal,
      // and check that every t_i is assignable to every s_i
      if (t.normalParameterTypes.length != s.normalParameterTypes.length) {
        return false;
      } else if (t.normalParameterTypes.length > 0) {
        for (int i = 0; i < tTypes.length; i++) {
          if (!(tTypes[i] as TypeImpl).isAssignableTo(sTypes[i])) {
            return false;
          }
        }
      }
      Map<String, DartType> namedTypesT = t.namedParameterTypes;
      Map<String, DartType> namedTypesS = s.namedParameterTypes;
      // if k >= m is false, return false: the passed function type has more
      // named parameter types than this
      if (namedTypesT.length < namedTypesS.length) {
        return false;
      }
      // Loop through each element in S verifying that T has a matching
      // parameter name and that the corresponding type is assignable to the
      // type in S.
      for (String keyS in namedTypesS.keys) {
        DartType typeT = namedTypesT[keyS];
        if (typeT == null) {
          return false;
        }
        if (!(typeT as TypeImpl).isAssignableTo(namedTypesS[keyS])) {
          return false;
        }
      }
    } else if (s.namedParameterTypes.length > 0) {
      return false;
    } else {
      // positional parameter case
      int tArgLength = tTypes.length + tOpTypes.length;
      int sArgLength = sTypes.length + sOpTypes.length;
      // Check that the total number of parameters in t is greater than or
      // equal to the number of parameters in s and that the number of
      // required parameters in s is greater than or equal to the number of
      // required parameters in t.
      if (tArgLength < sArgLength || sTypes.length < tTypes.length) {
        return false;
      }
      if (tOpTypes.length == 0 && sOpTypes.length == 0) {
        // No positional arguments, don't copy contents to new array
        for (int i = 0; i < sTypes.length; i++) {
          if (!(tTypes[i] as TypeImpl).isAssignableTo(sTypes[i])) {
            return false;
          }
        }
      } else {
        // Else, we do have positional parameters, copy required and
        // positional parameter types into arrays to do the compare (for loop
        // below).
        List<DartType> tAllTypes = new List<DartType>(sArgLength);
        for (int i = 0; i < tTypes.length; i++) {
          tAllTypes[i] = tTypes[i];
        }
        for (int i = tTypes.length, j = 0; i < sArgLength; i++, j++) {
          tAllTypes[i] = tOpTypes[j];
        }
        List<DartType> sAllTypes = new List<DartType>(sArgLength);
        for (int i = 0; i < sTypes.length; i++) {
          sAllTypes[i] = sTypes[i];
        }
        for (int i = sTypes.length, j = 0; i < sArgLength; i++, j++) {
          sAllTypes[i] = sOpTypes[j];
        }
        for (int i = 0; i < sAllTypes.length; i++) {
          if (!(tAllTypes[i] as TypeImpl).isAssignableTo(sAllTypes[i])) {
            return false;
          }
        }
      }
    }
    DartType tRetType = t.returnType;
    DartType sRetType = s.returnType;
    return sRetType.isVoid || (tRetType as TypeImpl).isAssignableTo(sRetType);
  }

  @override
  TypeImpl pruned(List<FunctionTypeAliasElement> prune) {
    if (prune == null) {
      return this;
    } else if (prune.contains(element)) {
      // Circularity found.  Prune the type declaration.
      return new CircularTypeImpl();
    } else {
      // There should never be a reason to prune a type that has already been
      // pruned, since pruning is only done when expanding a function type
      // alias, and function type aliases are always expanded by starting with
      // base types.
      assert(this.prunedTypedefs == null);
      List<DartType> typeArgs = typeArguments
          .map((TypeImpl t) => t.pruned(prune))
          .toList(growable: false);
      return new FunctionTypeImpl._(element, name, prune, typeArgs,
          _typeParameters, _boundTypeParameters);
    }
  }

  @override
  DartType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]) {
    // Pruned types should only ever result from performing type variable
    // substitution, and it doesn't make sense to substitute again after
    // substituting once.
    assert(this.prunedTypedefs == null);
    if (argumentTypes.length != parameterTypes.length) {
      throw new IllegalArgumentException(
          "argumentTypes.length (${argumentTypes.length}) != parameterTypes.length (${parameterTypes.length})");
    }
    Element element = this.element;
    if (prune != null && prune.contains(element)) {
      // Circularity found.  Prune the type declaration.
      return new CircularTypeImpl();
    }
    if (argumentTypes.length == 0) {
      return this.pruned(prune);
    }
    List<DartType> typeArgs =
        TypeImpl.substitute(typeArguments, argumentTypes, parameterTypes);
    return new FunctionTypeImpl._(
        element, name, prune, typeArgs, _typeParameters, _boundTypeParameters);
  }

  @override
  FunctionTypeImpl substitute3(List<DartType> argumentTypes) =>
      substitute2(argumentTypes, typeArguments);

  void _freeVariablesInFunctionType(
      FunctionType type, Set<TypeParameterType> free) {
    // Make some fresh variables to avoid capture.
    List<DartType> typeArgs = DartType.EMPTY_LIST;
    if (type.boundTypeParameters.isNotEmpty) {
      typeArgs = new List<DartType>.from(type.boundTypeParameters.map((e) =>
          new TypeParameterTypeImpl(new TypeParameterElementImpl(e.name, -1))));

      type = type.instantiate(typeArgs);
    }

    for (ParameterElement p in type.parameters) {
      _freeVariablesInType(p.type, free);
    }
    _freeVariablesInType(type.returnType, free);

    // Remove all of our bound variables.
    free.removeAll(typeArgs);
  }

  void _freeVariablesInInterfaceType(
      InterfaceType type, Set<TypeParameterType> free) {
    for (DartType typeArg in type.typeArguments) {
      _freeVariablesInType(typeArg, free);
    }
  }

  void _freeVariablesInType(DartType type, Set<TypeParameterType> free) {
    if (type is TypeParameterType) {
      free.add(type);
    } else if (type is FunctionType) {
      _freeVariablesInFunctionType(type, free);
    } else if (type is InterfaceType) {
      _freeVariablesInInterfaceType(type, free);
    }
  }

  /**
   * Compute the least upper bound of types [f] and [g], both of which are
   * known to be function types.
   *
   * In the event that f and g have different numbers of required parameters,
   * `null` is returned, in which case the least upper bound is the interface
   * type `Function`.
   */
  static FunctionType computeLeastUpperBound(FunctionType f, FunctionType g) {
    // TODO(paulberry): implement this.
    return null;
  }

  /**
   * Return `true` if all of the name/type pairs in the first map ([firstTypes])
   * are equal to the corresponding name/type pairs in the second map
   * ([secondTypes]). The maps are expected to iterate over their entries in the
   * same order in which those entries were added to the map.
   */
  static bool _equals(
      Map<String, DartType> firstTypes, Map<String, DartType> secondTypes) {
    if (secondTypes.length != firstTypes.length) {
      return false;
    }
    Iterator<String> firstKeys = firstTypes.keys.iterator;
    Iterator<String> secondKeys = secondTypes.keys.iterator;
    while (firstKeys.moveNext() && secondKeys.moveNext()) {
      String firstKey = firstKeys.current;
      String secondKey = secondKeys.current;
      TypeImpl firstType = firstTypes[firstKey];
      TypeImpl secondType = secondTypes[secondKey];
      if (firstKey != secondKey || firstType != secondType) {
        return false;
      }
    }
    return true;
  }
}

/**
 * A concrete implementation of an [InterfaceType].
 */
class InterfaceTypeImpl extends TypeImpl implements InterfaceType {
  /**
   * A list containing the actual types of the type arguments.
   */
  List<DartType> typeArguments = DartType.EMPTY_LIST;

  /**
   * The set of typedefs which should not be expanded when exploring this type,
   * to avoid creating infinite types in response to self-referential typedefs.
   */
  final List<FunctionTypeAliasElement> prunedTypedefs;

  /**
   * Initialize a newly created type to be declared by the given [element].
   */
  InterfaceTypeImpl(ClassElement element, [this.prunedTypedefs])
      : super(element, element.displayName);

  /**
   * Initialize a newly created type to be declared by the given [element],
   * with the given [name].
   */
  InterfaceTypeImpl.elementWithName(ClassElement element, String name)
      : prunedTypedefs = null,
        super(element, name);

  /**
   * Initialize a newly created type to have the given [name]. This constructor
   * should only be used in cases where there is no declaration of the type.
   */
  InterfaceTypeImpl.named(String name)
      : prunedTypedefs = null,
        super(null, name);

  /**
   * Private constructor.
   */
  InterfaceTypeImpl._(Element element, String name, this.prunedTypedefs)
      : super(element, name);

  @override
  List<PropertyAccessorElement> get accessors {
    List<PropertyAccessorElement> accessors = element.accessors;
    List<PropertyAccessorElement> members =
        new List<PropertyAccessorElement>(accessors.length);
    for (int i = 0; i < accessors.length; i++) {
      members[i] = PropertyAccessorMember.from(accessors[i], this);
    }
    return members;
  }

  @override
  List<ConstructorElement> get constructors {
    List<ConstructorElement> constructors = element.constructors;
    List<ConstructorElement> members =
        new List<ConstructorElement>(constructors.length);
    for (int i = 0; i < constructors.length; i++) {
      members[i] = ConstructorMember.from(constructors[i], this);
    }
    return members;
  }

  @override
  String get displayName {
    String name = this.name;
    List<DartType> typeArguments = this.typeArguments;
    bool allDynamic = true;
    for (DartType type in typeArguments) {
      if (type != null && !type.isDynamic) {
        allDynamic = false;
        break;
      }
    }
    // If there is at least one non-dynamic type, then list them out
    if (!allDynamic) {
      StringBuffer buffer = new StringBuffer();
      buffer.write(name);
      buffer.write("<");
      for (int i = 0; i < typeArguments.length; i++) {
        if (i != 0) {
          buffer.write(", ");
        }
        DartType typeArg = typeArguments[i];
        buffer.write(typeArg.displayName);
      }
      buffer.write(">");
      name = buffer.toString();
    }
    return name;
  }

  @override
  ClassElement get element => super.element as ClassElement;

  @override
  int get hashCode {
    ClassElement element = this.element;
    if (element == null) {
      return 0;
    }
    return element.hashCode;
  }

  @override
  List<InterfaceType> get interfaces {
    ClassElement classElement = element;
    List<InterfaceType> interfaces = classElement.interfaces;
    List<TypeParameterElement> typeParameters = classElement.typeParameters;
    List<DartType> parameterTypes = classElement.type.typeArguments;
    if (typeParameters.length == 0) {
      return interfaces;
    }
    int count = interfaces.length;
    List<InterfaceType> typedInterfaces = new List<InterfaceType>(count);
    for (int i = 0; i < count; i++) {
      typedInterfaces[i] =
          interfaces[i].substitute2(typeArguments, parameterTypes);
    }
    return typedInterfaces;
  }

  @override
  bool get isDartCoreFunction {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "Function" && element.library.isDartCore;
  }

  @override
  bool get isObject => element.supertype == null;

  @override
  List<MethodElement> get methods {
    List<MethodElement> methods = element.methods;
    List<MethodElement> members = new List<MethodElement>(methods.length);
    for (int i = 0; i < methods.length; i++) {
      members[i] = MethodMember.from(methods[i], this);
    }
    return members;
  }

  @override
  List<InterfaceType> get mixins {
    ClassElement classElement = element;
    List<InterfaceType> mixins = classElement.mixins;
    List<TypeParameterElement> typeParameters = classElement.typeParameters;
    List<DartType> parameterTypes = classElement.type.typeArguments;
    if (typeParameters.length == 0) {
      return mixins;
    }
    int count = mixins.length;
    List<InterfaceType> typedMixins = new List<InterfaceType>(count);
    for (int i = 0; i < count; i++) {
      typedMixins[i] = mixins[i].substitute2(typeArguments, parameterTypes);
    }
    return typedMixins;
  }

  @override
  InterfaceType get superclass {
    ClassElement classElement = element;
    InterfaceType supertype = classElement.supertype;
    if (supertype == null) {
      return null;
    }
    List<DartType> typeParameters = classElement.type.typeArguments;
    if (typeArguments.length == 0 ||
        typeArguments.length != typeParameters.length) {
      return supertype;
    }
    return supertype.substitute2(typeArguments, typeParameters);
  }

  @override
  List<TypeParameterElement> get typeParameters => element.typeParameters;

  @override
  bool operator ==(Object object) {
    if (identical(object, this)) {
      return true;
    }
    if (object is! InterfaceTypeImpl) {
      return false;
    }
    InterfaceTypeImpl otherType = object as InterfaceTypeImpl;
    return (element == otherType.element) &&
        TypeImpl.equalArrays(typeArguments, otherType.typeArguments);
  }

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write(name);
    int argumentCount = typeArguments.length;
    if (argumentCount > 0) {
      buffer.write("<");
      for (int i = 0; i < argumentCount; i++) {
        if (i > 0) {
          buffer.write(", ");
        }
        (typeArguments[i] as TypeImpl).appendTo(buffer);
      }
      buffer.write(">");
    }
  }

  @override
  PropertyAccessorElement getGetter(String getterName) => PropertyAccessorMember
      .from((element as ClassElementImpl).getGetter(getterName), this);

  @override
  MethodElement getMethod(String methodName) => MethodMember.from(
      (element as ClassElementImpl).getMethod(methodName), this);

  @override
  PropertyAccessorElement getSetter(String setterName) => PropertyAccessorMember
      .from((element as ClassElementImpl).getSetter(setterName), this);

  @override
  bool isDirectSupertypeOf(InterfaceType type) {
    InterfaceType i = this;
    InterfaceType j = type;
    ClassElement jElement = j.element;
    InterfaceType supertype = jElement.supertype;
    //
    // If J has no direct supertype then it is Object, and Object has no direct
    // supertypes.
    //
    if (supertype == null) {
      return false;
    }
    //
    // I is listed in the extends clause of J.
    //
    List<DartType> jArgs = j.typeArguments;
    List<DartType> jVars = jElement.type.typeArguments;
    supertype = supertype.substitute2(jArgs, jVars);
    if (supertype == i) {
      return true;
    }
    //
    // I is listed in the implements clause of J.
    //
    for (InterfaceType interfaceType in jElement.interfaces) {
      interfaceType = interfaceType.substitute2(jArgs, jVars);
      if (interfaceType == i) {
        return true;
      }
    }
    //
    // I is listed in the with clause of J.
    //
    for (InterfaceType mixinType in jElement.mixins) {
      mixinType = mixinType.substitute2(jArgs, jVars);
      if (mixinType == i) {
        return true;
      }
    }
    //
    // J is a mixin application of the mixin of I.
    //
    // TODO(brianwilkerson) Determine whether this needs to be implemented or
    // whether it is covered by the case above.
    return false;
  }

  @override
  bool isMoreSpecificThan(DartType type,
      [bool withDynamic = false, Set<Element> visitedElements]) {
    //
    // S is dynamic.
    // The test to determine whether S is dynamic is done here because dynamic
    // is not an instance of InterfaceType.
    //
    if (type.isDynamic) {
      return true;
    }
    //
    // A type T is more specific than a type S, written T << S,
    // if one of the following conditions is met:
    //
    // Reflexivity: T is S.
    //
    if (this == type) {
      return true;
    }
    if (type is InterfaceType) {
      //
      // T is bottom. (This case is handled by the class BottomTypeImpl.)
      //
      // Direct supertype: S is a direct supertype of T.
      //
      if (type.isDirectSupertypeOf(this)) {
        return true;
      }
      //
      // Covariance: T is of the form I<T1, ..., Tn> and S is of the form
      // I<S1, ..., Sn> and Ti << Si, 1 <= i <= n.
      //
      ClassElement tElement = this.element;
      ClassElement sElement = type.element;
      if (tElement == sElement) {
        List<DartType> tArguments = typeArguments;
        List<DartType> sArguments = type.typeArguments;
        if (tArguments.length != sArguments.length) {
          return false;
        }
        for (int i = 0; i < tArguments.length; i++) {
          if (!(tArguments[i] as TypeImpl)
              .isMoreSpecificThan(sArguments[i], withDynamic)) {
            return false;
          }
        }
        return true;
      }
    }
    //
    // Transitivity: T << U and U << S.
    //
    // First check for infinite loops
    if (element == null) {
      return false;
    }
    if (visitedElements == null) {
      visitedElements = new HashSet<ClassElement>();
    } else if (visitedElements.contains(element)) {
      return false;
    }
    visitedElements.add(element);
    try {
      // Iterate over all of the types U that are more specific than T because
      // they are direct supertypes of T and return true if any of them are more
      // specific than S.
      InterfaceTypeImpl supertype = superclass;
      if (supertype != null &&
          supertype.isMoreSpecificThan(type, withDynamic, visitedElements)) {
        return true;
      }
      for (InterfaceType interfaceType in interfaces) {
        if ((interfaceType as InterfaceTypeImpl)
            .isMoreSpecificThan(type, withDynamic, visitedElements)) {
          return true;
        }
      }
      for (InterfaceType mixinType in mixins) {
        if ((mixinType as InterfaceTypeImpl)
            .isMoreSpecificThan(type, withDynamic, visitedElements)) {
          return true;
        }
      }
      // If a type I includes an instance method named `call`, and the type of
      // `call` is the function type F, then I is considered to be more specific
      // than F.
      MethodElement callMethod = getMethod('call');
      if (callMethod != null && !callMethod.isStatic) {
        FunctionTypeImpl callType = callMethod.type;
        if (callType.isMoreSpecificThan(type, withDynamic, visitedElements)) {
          return true;
        }
      }
      return false;
    } finally {
      visitedElements.remove(element);
    }
  }

  @override
  ConstructorElement lookUpConstructor(
      String constructorName, LibraryElement library) {
    // prepare base ConstructorElement
    ConstructorElement constructorElement;
    if (constructorName == null) {
      constructorElement = element.unnamedConstructor;
    } else {
      constructorElement = element.getNamedConstructor(constructorName);
    }
    // not found or not accessible
    if (constructorElement == null ||
        !constructorElement.isAccessibleIn(library)) {
      return null;
    }
    // return member
    return ConstructorMember.from(constructorElement, this);
  }

  @override
  PropertyAccessorElement lookUpGetter(
      String getterName, LibraryElement library) {
    PropertyAccessorElement element = getGetter(getterName);
    if (element != null && element.isAccessibleIn(library)) {
      return element;
    }
    return lookUpGetterInSuperclass(getterName, library);
  }

  @override
  PropertyAccessorElement lookUpGetterInSuperclass(
      String getterName, LibraryElement library) {
    for (InterfaceType mixin in mixins.reversed) {
      PropertyAccessorElement element = mixin.getGetter(getterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
    InterfaceType supertype = superclass;
    ClassElement supertypeElement =
        supertype == null ? null : supertype.element;
    while (supertype != null && !visitedClasses.contains(supertypeElement)) {
      visitedClasses.add(supertypeElement);
      PropertyAccessorElement element = supertype.getGetter(getterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
      for (InterfaceType mixin in supertype.mixins.reversed) {
        element = mixin.getGetter(getterName);
        if (element != null && element.isAccessibleIn(library)) {
          return element;
        }
      }
      supertype = supertype.superclass;
      supertypeElement = supertype == null ? null : supertype.element;
    }
    return null;
  }

  @override
  PropertyAccessorElement lookUpInheritedGetter(String name,
      {LibraryElement library, bool thisType: true}) {
    PropertyAccessorElement result;
    if (thisType) {
      result = lookUpGetter(name, library);
    } else {
      result = lookUpGetterInSuperclass(name, library);
    }
    if (result != null) {
      return result;
    }
    return _lookUpMemberInInterfaces(this, false, library,
        new HashSet<ClassElement>(), (InterfaceType t) => t.getGetter(name));
  }

  @override
  ExecutableElement lookUpInheritedGetterOrMethod(String name,
      {LibraryElement library}) {
    ExecutableElement result =
        lookUpGetter(name, library) ?? lookUpMethod(name, library);

    if (result != null) {
      return result;
    }
    return _lookUpMemberInInterfaces(
        this,
        false,
        library,
        new HashSet<ClassElement>(),
        (InterfaceType t) => t.getGetter(name) ?? t.getMethod(name));
  }

  @override
  MethodElement lookUpInheritedMethod(String name,
      {LibraryElement library, bool thisType: true}) {
    MethodElement result;
    if (thisType) {
      result = lookUpMethod(name, library);
    } else {
      result = lookUpMethodInSuperclass(name, library);
    }
    if (result != null) {
      return result;
    }
    return _lookUpMemberInInterfaces(this, false, library,
        new HashSet<ClassElement>(), (InterfaceType t) => t.getMethod(name));
  }

  @override
  PropertyAccessorElement lookUpInheritedSetter(String name,
      {LibraryElement library, bool thisType: true}) {
    PropertyAccessorElement result;
    if (thisType) {
      result = lookUpSetter(name, library);
    } else {
      result = lookUpSetterInSuperclass(name, library);
    }
    if (result != null) {
      return result;
    }
    return _lookUpMemberInInterfaces(this, false, library,
        new HashSet<ClassElement>(), (t) => t.getSetter(name));
  }

  @override
  MethodElement lookUpMethod(String methodName, LibraryElement library) {
    MethodElement element = getMethod(methodName);
    if (element != null && element.isAccessibleIn(library)) {
      return element;
    }
    return lookUpMethodInSuperclass(methodName, library);
  }

  @override
  MethodElement lookUpMethodInSuperclass(
      String methodName, LibraryElement library) {
    for (InterfaceType mixin in mixins.reversed) {
      MethodElement element = mixin.getMethod(methodName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
    InterfaceType supertype = superclass;
    ClassElement supertypeElement =
        supertype == null ? null : supertype.element;
    while (supertype != null && !visitedClasses.contains(supertypeElement)) {
      visitedClasses.add(supertypeElement);
      MethodElement element = supertype.getMethod(methodName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
      for (InterfaceType mixin in supertype.mixins.reversed) {
        element = mixin.getMethod(methodName);
        if (element != null && element.isAccessibleIn(library)) {
          return element;
        }
      }
      supertype = supertype.superclass;
      supertypeElement = supertype == null ? null : supertype.element;
    }
    return null;
  }

  @override
  PropertyAccessorElement lookUpSetter(
      String setterName, LibraryElement library) {
    PropertyAccessorElement element = getSetter(setterName);
    if (element != null && element.isAccessibleIn(library)) {
      return element;
    }
    return lookUpSetterInSuperclass(setterName, library);
  }

  @override
  PropertyAccessorElement lookUpSetterInSuperclass(
      String setterName, LibraryElement library) {
    for (InterfaceType mixin in mixins.reversed) {
      PropertyAccessorElement element = mixin.getSetter(setterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
    InterfaceType supertype = superclass;
    ClassElement supertypeElement =
        supertype == null ? null : supertype.element;
    while (supertype != null && !visitedClasses.contains(supertypeElement)) {
      visitedClasses.add(supertypeElement);
      PropertyAccessorElement element = supertype.getSetter(setterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
      for (InterfaceType mixin in supertype.mixins.reversed) {
        element = mixin.getSetter(setterName);
        if (element != null && element.isAccessibleIn(library)) {
          return element;
        }
      }
      supertype = supertype.superclass;
      supertypeElement = supertype == null ? null : supertype.element;
    }
    return null;
  }

  @override
  InterfaceTypeImpl pruned(List<FunctionTypeAliasElement> prune) {
    if (prune == null) {
      return this;
    } else {
      // There should never be a reason to prune a type that has already been
      // pruned, since pruning is only done when expanding a function type
      // alias, and function type aliases are always expanded by starting with
      // base types.
      assert(this.prunedTypedefs == null);
      InterfaceTypeImpl result = new InterfaceTypeImpl._(element, name, prune);
      result.typeArguments =
          typeArguments.map((TypeImpl t) => t.pruned(prune)).toList();
      return result;
    }
  }

  @override
  InterfaceTypeImpl substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]) {
    if (argumentTypes.length != parameterTypes.length) {
      throw new IllegalArgumentException(
          "argumentTypes.length (${argumentTypes.length}) != parameterTypes.length (${parameterTypes.length})");
    }
    if (argumentTypes.length == 0 || typeArguments.length == 0) {
      return this.pruned(prune);
    }
    List<DartType> newTypeArguments = TypeImpl.substitute(
        typeArguments, argumentTypes, parameterTypes, prune);
    if (JavaArrays.equals(newTypeArguments, typeArguments)) {
      return this;
    }
    InterfaceTypeImpl newType = new InterfaceTypeImpl(element, prune);
    newType.typeArguments = newTypeArguments;
    return newType;
  }

  @override
  InterfaceTypeImpl substitute4(List<DartType> argumentTypes) =>
      substitute2(argumentTypes, typeArguments);

  /**
   * Compute the least upper bound of types [i] and [j], both of which are
   * known to be interface types.
   *
   * In the event that the algorithm fails (which might occur due to a bug in
   * the analyzer), `null` is returned.
   */
  static InterfaceType computeLeastUpperBound(
      InterfaceType i, InterfaceType j) {
    // compute set of supertypes
    Set<InterfaceType> si = computeSuperinterfaceSet(i);
    Set<InterfaceType> sj = computeSuperinterfaceSet(j);
    // union si with i and sj with j
    si.add(i);
    sj.add(j);
    // compute intersection, reference as set 's'
    List<InterfaceType> s = _intersection(si, sj);
    // for each element in Set s, compute the largest inheritance path to Object
    List<int> depths = new List<int>.filled(s.length, 0);
    int maxDepth = 0;
    for (int n = 0; n < s.length; n++) {
      depths[n] = computeLongestInheritancePathToObject(s[n]);
      if (depths[n] > maxDepth) {
        maxDepth = depths[n];
      }
    }
    // ensure that the currently computed maxDepth is unique,
    // otherwise, decrement and test for uniqueness again
    for (; maxDepth >= 0; maxDepth--) {
      int indexOfLeastUpperBound = -1;
      int numberOfTypesAtMaxDepth = 0;
      for (int m = 0; m < depths.length; m++) {
        if (depths[m] == maxDepth) {
          numberOfTypesAtMaxDepth++;
          indexOfLeastUpperBound = m;
        }
      }
      if (numberOfTypesAtMaxDepth == 1) {
        return s[indexOfLeastUpperBound];
      }
    }
    // Should be impossible--there should always be exactly one type with the
    // maximum depth.
    assert(false);
    return null;
  }

  /**
   * Return the length of the longest inheritance path from the given [type] to
   * Object.
   *
   * See [computeLeastUpperBound].
   */
  static int computeLongestInheritancePathToObject(InterfaceType type) =>
      _computeLongestInheritancePathToObject(
          type, 0, new HashSet<ClassElement>());

  /**
   * Returns the set of all superinterfaces of the given [type].
   *
   * See [computeLeastUpperBound].
   */
  static Set<InterfaceType> computeSuperinterfaceSet(InterfaceType type) =>
      _computeSuperinterfaceSet(type, new HashSet<InterfaceType>());

  /**
   * Returns a "smart" version of the "least upper bound" of the given types.
   *
   * If these types have the same element and differ only in terms of the type
   * arguments, attempts to find a compatible set of type arguments.
   *
   * Otherwise, calls [DartType.getLeastUpperBound].
   */
  static InterfaceType getSmartLeastUpperBound(
      InterfaceType first, InterfaceType second) {
    // TODO(paulberry): this needs to be deprecated and replaced with a method
    // in [TypeSystem], since it relies on the deprecated functionality of
    // [DartType.getLeastUpperBound].
    if (first.element == second.element) {
      return _leastUpperBound(first, second);
    }
    AnalysisContext context = first.element.context;
    return context.typeSystem
        .getLeastUpperBound(context.typeProvider, first, second);
  }

  /**
   * Return the length of the longest inheritance path from a subtype of the
   * given [type] to Object, where the given [depth] is the length of the
   * longest path from the subtype to this type. The set of [visitedTypes] is
   * used to prevent infinite recursion in the case of a cyclic type structure.
   *
   * See [computeLongestInheritancePathToObject], and [computeLeastUpperBound].
   */
  static int _computeLongestInheritancePathToObject(
      InterfaceType type, int depth, HashSet<ClassElement> visitedTypes) {
    ClassElement classElement = type.element;
    // Object case
    if (classElement.supertype == null || visitedTypes.contains(classElement)) {
      return depth;
    }
    int longestPath = 1;
    try {
      visitedTypes.add(classElement);
      List<InterfaceType> superinterfaces = classElement.interfaces;
      int pathLength;
      if (superinterfaces.length > 0) {
        // loop through each of the superinterfaces recursively calling this
        // method and keeping track of the longest path to return
        for (InterfaceType superinterface in superinterfaces) {
          pathLength = _computeLongestInheritancePathToObject(
              superinterface, depth + 1, visitedTypes);
          if (pathLength > longestPath) {
            longestPath = pathLength;
          }
        }
      }
      // finally, perform this same check on the super type
      // TODO(brianwilkerson) Does this also need to add in the number of mixin
      // classes?
      InterfaceType supertype = classElement.supertype;
      pathLength = _computeLongestInheritancePathToObject(
          supertype, depth + 1, visitedTypes);
      if (pathLength > longestPath) {
        longestPath = pathLength;
      }
    } finally {
      visitedTypes.remove(classElement);
    }
    return longestPath;
  }

  /**
   * Add all of the superinterfaces of the given [type] to the given [set].
   * Return the [set] as a convenience.
   *
   * See [computeSuperinterfaceSet], and [computeLeastUpperBound].
   */
  static Set<InterfaceType> _computeSuperinterfaceSet(
      InterfaceType type, HashSet<InterfaceType> set) {
    Element element = type.element;
    if (element != null) {
      List<InterfaceType> superinterfaces = type.interfaces;
      for (InterfaceType superinterface in superinterfaces) {
        if (set.add(superinterface)) {
          _computeSuperinterfaceSet(superinterface, set);
        }
      }
      InterfaceType supertype = type.superclass;
      if (supertype != null) {
        if (set.add(supertype)) {
          _computeSuperinterfaceSet(supertype, set);
        }
      }
    }
    return set;
  }

  /**
   * Return the intersection of the [first] and [second] sets of types, where
   * intersection is based on the equality of the types themselves.
   */
  static List<InterfaceType> _intersection(
      Set<InterfaceType> first, Set<InterfaceType> second) {
    Set<InterfaceType> result = new HashSet<InterfaceType>.from(first);
    result.retainAll(second);
    return new List.from(result);
  }

  /**
   * Return the "least upper bound" of the given types under the assumption that
   * the types have the same element and differ only in terms of the type
   * arguments.
   *
   * The resulting type is composed by comparing the corresponding type
   * arguments, keeping those that are the same, and using 'dynamic' for those
   * that are different.
   */
  static InterfaceType _leastUpperBound(
      InterfaceType firstType, InterfaceType secondType) {
    ClassElement firstElement = firstType.element;
    ClassElement secondElement = secondType.element;
    if (firstElement != secondElement) {
      throw new IllegalArgumentException('The same elements expected, but '
          '$firstElement and $secondElement are given.');
    }
    if (firstType == secondType) {
      return firstType;
    }
    List<DartType> firstArguments = firstType.typeArguments;
    List<DartType> secondArguments = secondType.typeArguments;
    int argumentCount = firstArguments.length;
    if (argumentCount == 0) {
      return firstType;
    }
    List<DartType> lubArguments = new List<DartType>(argumentCount);
    for (int i = 0; i < argumentCount; i++) {
      //
      // Ideally we would take the least upper bound of the two argument types,
      // but this can cause an infinite recursion (such as when finding the
      // least upper bound of String and num).
      //
      if (firstArguments[i] == secondArguments[i]) {
        lubArguments[i] = firstArguments[i];
      }
      if (lubArguments[i] == null) {
        lubArguments[i] = DynamicTypeImpl.instance;
      }
    }
    InterfaceTypeImpl lub = new InterfaceTypeImpl(firstElement);
    lub.typeArguments = lubArguments;
    return lub;
  }

  /**
   * Look up the getter with the given [name] in the interfaces
   * implemented by the given [targetType], either directly or indirectly.
   * Return the element representing the getter that was found, or `null` if
   * there is no getter with the given name. The flag [includeTargetType] should
   * be `true` if the search should include the target type. The
   * [visitedInterfaces] is a set containing all of the interfaces that have
   * been examined, used to prevent infinite recursion and to optimize the
   * search.
   */
  static ExecutableElement _lookUpMemberInInterfaces(
      InterfaceType targetType,
      bool includeTargetType,
      LibraryElement library,
      HashSet<ClassElement> visitedInterfaces,
      ExecutableElement getMember(InterfaceType type)) {
    // TODO(brianwilkerson) This isn't correct. Section 8.1.1 of the
    // specification (titled "Inheritance and Overriding" under "Interfaces")
    // describes a much more complex scheme for finding the inherited member.
    // We need to follow that scheme. The code below should cover the 80% case.
    ClassElement targetClass = targetType.element;
    if (!visitedInterfaces.add(targetClass)) {
      return null;
    }
    if (includeTargetType) {
      ExecutableElement member = getMember(targetType);
      if (member != null && member.isAccessibleIn(library)) {
        return member;
      }
    }
    for (InterfaceType interfaceType in targetType.interfaces) {
      ExecutableElement member = _lookUpMemberInInterfaces(
          interfaceType, true, library, visitedInterfaces, getMember);
      if (member != null) {
        return member;
      }
    }
    for (InterfaceType mixinType in targetType.mixins.reversed) {
      ExecutableElement member = _lookUpMemberInInterfaces(
          mixinType, true, library, visitedInterfaces, getMember);
      if (member != null) {
        return member;
      }
    }
    InterfaceType superclass = targetType.superclass;
    if (superclass == null) {
      return null;
    }
    return _lookUpMemberInInterfaces(
        superclass, true, library, visitedInterfaces, getMember);
  }
}

/**
 * The abstract class `TypeImpl` implements the behavior common to objects
 * representing the declared type of elements in the element model.
 */
abstract class TypeImpl implements DartType {
  /**
   * The element representing the declaration of this type, or `null` if the
   * type has not, or cannot, be associated with an element.
   */
  final Element _element;

  /**
   * The name of this type, or `null` if the type does not have a name.
   */
  final String name;

  /**
   * Initialize a newly created type to be declared by the given [element] and
   * to have the given [name].
   */
  TypeImpl(this._element, this.name);

  @override
  String get displayName => name;

  @override
  Element get element => _element;

  @override
  bool get isBottom => false;

  @override
  bool get isDartCoreFunction => false;

  @override
  bool get isDynamic => false;

  @override
  bool get isObject => false;

  @override
  bool get isUndefined => false;

  @override
  bool get isVoid => false;

  /**
   * Append a textual representation of this type to the given [buffer]. The set
   * of [visitedTypes] is used to prevent infinite recursion.
   */
  void appendTo(StringBuffer buffer) {
    if (name == null) {
      buffer.write("<unnamed type>");
    } else {
      buffer.write(name);
    }
  }

  /**
   * Return `true` if this type is assignable to the given [type] (written in
   * the spec as "T <=> S", where T=[this] and S=[type]).
   *
   * The sets [thisExpansions] and [typeExpansions], if given, are the sets of
   * function type aliases that have been expanded so far in the process of
   * reaching [this] and [type], respectively.  These are used to avoid
   * infinite regress when analyzing invalid code; since the language spec
   * forbids a typedef from referring to itself directly or indirectly, we can
   * use these as sets of function type aliases that don't need to be expanded.
   */
  @override
  bool isAssignableTo(DartType type) {
    // An interface type T may be assigned to a type S, written T <=> S, iff
    // either T <: S or S <: T.
    return isSubtypeOf(type) || (type as TypeImpl).isSubtypeOf(this);
  }

  /**
   * Return `true` if this type is more specific than the given [type] (written
   * in the spec as "T << S", where T=[this] and S=[type]).
   *
   * If [withDynamic] is `true`, then "dynamic" should be considered as a
   * subtype of any type (as though "dynamic" had been replaced with bottom).
   *
   * The set [visitedElements], if given, is the set of classes and type
   * parameters that have been visited so far while examining the class
   * hierarchy of [this].  This is used to avoid infinite regress when
   * analyzing invalid code; since the language spec forbids loops in the class
   * hierarchy, we can use this as a set of classes that don't need to be
   * examined when walking the class hierarchy.
   */
  @override
  bool isMoreSpecificThan(DartType type,
      [bool withDynamic = false, Set<Element> visitedElements]);

  /**
   * Return `true` if this type is a subtype of the given [type] (written in
   * the spec as "T <: S", where T=[this] and S=[type]).
   *
   * The sets [thisExpansions] and [typeExpansions], if given, are the sets of
   * function type aliases that have been expanded so far in the process of
   * reaching [this] and [type], respectively.  These are used to avoid
   * infinite regress when analyzing invalid code; since the language spec
   * forbids a typedef from referring to itself directly or indirectly, we can
   * use these as sets of function type aliases that don't need to be expanded.
   */
  @override
  bool isSubtypeOf(DartType type) {
    // For non-function types, T <: S iff [_|_/dynamic]T << S.
    return isMoreSpecificThan(type, true);
  }

  @override
  bool isSupertypeOf(DartType type) => type.isSubtypeOf(this);

  /**
   * Create a new [TypeImpl] that is identical to [this] except that when
   * visiting type parameters, function parameter types, and function return
   * types, function types listed in [prune] will not be expanded.  This is
   * used to avoid creating infinite types in the presence of circular
   * typedefs.
   *
   * If [prune] is null, then [this] is returned unchanged.
   *
   * Only legal to call on a [TypeImpl] that is not already subject to pruning.
   */
  TypeImpl pruned(List<FunctionTypeAliasElement> prune);

  /**
   * Return the type resulting from substituting the given [argumentTypes] for
   * the given [parameterTypes] in this type.
   *
   * In all classes derived from [TypeImpl], a new optional argument
   * [prune] is added.  If specified, it is a list of function typdefs
   * which should not be expanded.  This is used to avoid creating infinite
   * types in response to self-referential typedefs.
   */
  @override
  DartType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]);

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    appendTo(buffer);
    return buffer.toString();
  }

  /**
   * Return `true` if corresponding elements of the [first] and [second] lists
   * of type arguments are all equal.
   */
  static bool equalArrays(List<DartType> first, List<DartType> second) {
    if (first.length != second.length) {
      return false;
    }
    for (int i = 0; i < first.length; i++) {
      if (first[i] == null) {
        AnalysisEngine.instance.logger
            .logInformation('Found null type argument in TypeImpl.equalArrays');
        return second[i] == null;
      } else if (second[i] == null) {
        AnalysisEngine.instance.logger
            .logInformation('Found null type argument in TypeImpl.equalArrays');
        return false;
      }
      if (first[i] != second[i]) {
        return false;
      }
    }
    return true;
  }

  /**
   * Return a list containing the results of using the given [argumentTypes] and
   * [parameterTypes] to perform a substitution on all of the given [types].
   *
   * If [prune] is specified, it is a list of function typdefs which should not
   * be expanded.  This is used to avoid creating infinite types in response to
   * self-referential typedefs.
   */
  static List<DartType> substitute(List<DartType> types,
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]) {
    int length = types.length;
    if (length == 0) {
      return types;
    }
    List<DartType> newTypes = new List<DartType>(length);
    for (int i = 0; i < length; i++) {
      newTypes[i] = (types[i] as TypeImpl)
          .substitute2(argumentTypes, parameterTypes, prune);
    }
    return newTypes;
  }
}

/**
 * A concrete implementation of a [TypeParameterType].
 */
class TypeParameterTypeImpl extends TypeImpl implements TypeParameterType {
  /**
   * Initialize a newly created type parameter type to be declared by the given
   * [element] and to have the given name.
   */
  TypeParameterTypeImpl(TypeParameterElement element)
      : super(element, element.name);

  @override
  TypeParameterElement get element => super.element as TypeParameterElement;

  @override
  int get hashCode => element.hashCode;

  @override
  bool operator ==(Object object) =>
      object is TypeParameterTypeImpl && (element == object.element);

  @override
  bool isMoreSpecificThan(DartType s,
      [bool withDynamic = false, Set<Element> visitedElements]) {
    //
    // A type T is more specific than a type S, written T << S,
    // if one of the following conditions is met:
    //
    // Reflexivity: T is S.
    //
    if (this == s) {
      return true;
    }
    // S is dynamic.
    //
    if (s.isDynamic) {
      return true;
    }
    //
    // T is a type parameter and S is the upper bound of T.
    //
    TypeImpl bound = element.bound;
    if (s == bound) {
      return true;
    }
    //
    // T is a type parameter and S is Object.
    //
    if (s.isObject) {
      return true;
    }
    // We need upper bound to continue.
    if (bound == null) {
      return false;
    }
    //
    // Transitivity: T << U and U << S.
    //
    // First check for infinite loops
    if (element == null) {
      return false;
    }
    if (visitedElements == null) {
      visitedElements = new HashSet<Element>();
    } else if (visitedElements.contains(element)) {
      return false;
    }
    visitedElements.add(element);
    try {
      return bound.isMoreSpecificThan(s, withDynamic, visitedElements);
    } finally {
      visitedElements.remove(element);
    }
  }

  @override
  bool isSubtypeOf(DartType type) => isMoreSpecificThan(type, true);

  @override
  TypeImpl pruned(List<FunctionTypeAliasElement> prune) => this;

  @override
  DartType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]) {
    int length = parameterTypes.length;
    for (int i = 0; i < length; i++) {
      if (parameterTypes[i] == this) {
        return argumentTypes[i];
      }
    }
    return this;
  }

  /**
   * Return a list containing the type parameter types defined by the given
   * array of type parameter elements ([typeParameters]).
   */
  static List<TypeParameterType> getTypes(
      List<TypeParameterElement> typeParameters) {
    int count = typeParameters.length;
    if (count == 0) {
      return TypeParameterType.EMPTY_LIST;
    }
    List<TypeParameterType> types = new List<TypeParameterType>(count);
    for (int i = 0; i < count; i++) {
      types[i] = typeParameters[i].type;
    }
    return types;
  }
}

/**
 * The unique instance of the class `UndefinedTypeImpl` implements the type of
 * type names that couldn't be resolved.
 *
 * This class behaves like DynamicTypeImpl in almost every respect, to reduce
 * cascading errors.
 */
class UndefinedTypeImpl extends TypeImpl {
  /**
   * The unique instance of this class.
   */
  static UndefinedTypeImpl _INSTANCE = new UndefinedTypeImpl._();

  /**
   * Return the unique instance of this class.
   */
  static UndefinedTypeImpl get instance => _INSTANCE;

  /**
   * Prevent the creation of instances of this class.
   */
  UndefinedTypeImpl._()
      : super(DynamicElementImpl.instance, Keyword.DYNAMIC.syntax);

  @override
  int get hashCode => 1;

  @override
  bool get isDynamic => true;

  @override
  bool get isUndefined => true;

  @override
  bool operator ==(Object object) => identical(object, this);

  @override
  bool isMoreSpecificThan(DartType type,
      [bool withDynamic = false, Set<Element> visitedElements]) {
    // T is S
    if (identical(this, type)) {
      return true;
    }
    // else
    return withDynamic;
  }

  @override
  bool isSubtypeOf(DartType type) => true;

  @override
  bool isSupertypeOf(DartType type) => true;

  @override
  TypeImpl pruned(List<FunctionTypeAliasElement> prune) => this;

  @override
  DartType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]) {
    int length = parameterTypes.length;
    for (int i = 0; i < length; i++) {
      if (parameterTypes[i] == this) {
        return argumentTypes[i];
      }
    }
    return this;
  }
}

/**
 * The type `void`.
 */
abstract class VoidType implements DartType {
  @override
  VoidType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes);
}

/**
 * A concrete implementation of a [VoidType].
 */
class VoidTypeImpl extends TypeImpl implements VoidType {
  /**
   * The unique instance of this class.
   */
  static VoidTypeImpl _INSTANCE = new VoidTypeImpl();

  /**
   * Return the unique instance of this class.
   */
  static VoidTypeImpl get instance => _INSTANCE;

  /**
   * Prevent the creation of instances of this class.
   */
  VoidTypeImpl() : super(null, Keyword.VOID.syntax);

  @override
  int get hashCode => 2;

  @override
  bool get isVoid => true;

  @override
  bool operator ==(Object object) => identical(object, this);

  @override
  bool isMoreSpecificThan(DartType type,
          [bool withDynamic = false, Set<Element> visitedElements]) =>
      isSubtypeOf(type);

  @override
  bool isSubtypeOf(DartType type) {
    // The only subtype relations that pertain to void are therefore:
    // void <: void (by reflexivity)
    // bottom <: void (as bottom is a subtype of all types).
    // void <: dynamic (as dynamic is a supertype of all types)
    return identical(type, this) || type.isDynamic;
  }

  @override
  TypeImpl pruned(List<FunctionTypeAliasElement> prune) => this;

  @override
  VoidTypeImpl substitute2(
          List<DartType> argumentTypes, List<DartType> parameterTypes,
          [List<FunctionTypeAliasElement> prune]) =>
      this;
}
