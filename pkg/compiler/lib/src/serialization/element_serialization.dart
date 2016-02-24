// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.elements;

import '../common.dart';
import '../constants/constructors.dart';
import '../constants/expressions.dart';
import '../dart_types.dart';
import '../elements/elements.dart';
import 'constant_serialization.dart';
import 'keys.dart';
import 'modelz.dart';
import 'serialization.dart';

/// Enum kinds used for encoding [Element]s.
enum SerializedElementKind {
  LIBRARY,
  COMPILATION_UNIT,
  CLASS,
  GENERATIVE_CONSTRUCTOR,
  FACTORY_CONSTRUCTOR,
  TOPLEVEL_FIELD,
  STATIC_FIELD,
  INSTANCE_FIELD,
  TOPLEVEL_FUNCTION,
  TOPLEVEL_GETTER,
  TOPLEVEL_SETTER,
  STATIC_FUNCTION,
  STATIC_GETTER,
  STATIC_SETTER,
  INSTANCE_FUNCTION,
  INSTANCE_GETTER,
  INSTANCE_SETTER,
  TYPEDEF,
  TYPEVARIABLE,
  PARAMETER,
  INITIALIZING_FORMAL,
  IMPORT,
  EXPORT,
  PREFIX,
}

/// Set of serializers used to serialize different kinds of elements by
/// encoding into them into [ObjectEncoder]s.
///
/// This class is called from the [Serializer] when an [Element] needs
/// serialization. The [ObjectEncoder] ensures that any [Element], [DartType],
/// and [ConstantExpression] that the serialized [Element] depends upon are also
/// serialized.
const List<ElementSerializer> ELEMENT_SERIALIZERS = const [
    const LibrarySerializer(),
    const CompilationUnitSerializer(),
    const ClassSerializer(),
    const ConstructorSerializer(),
    const FieldSerializer(),
    const FunctionSerializer(),
    const TypedefSerializer(),
    const TypeVariableSerializer(),
    const ParameterSerializer(),
    const ImportSerializer(),
    const ExportSerializer(),
    const PrefixSerializer(),
];

/// Interface for a function that can serialize a set of element kinds.
abstract class ElementSerializer {
  /// Returns the [SerializedElementKind] for [element] if this serializer
  /// supports serialization of [element] or `null` otherwise.
  SerializedElementKind getSerializedKind(Element element);

  /// Serializes [element] into the [encoder] using the [kind] computed
  /// by [getSerializedKind].
  void serialize(Element element,
                 ObjectEncoder encoder,
                 SerializedElementKind kind);
}

class SerializerUtil {
  /// Serialize the declared members of [element] into [encoder].
  static void serializeMembers(ScopeContainerElement element,
                               ObjectEncoder encoder) {
    MapEncoder mapEncoder = encoder.createMap(Key.MEMBERS);
    element.forEachLocalMember((Element member) {
      String name = member.name;
      if (member.isSetter) {
        name = '$name,=';
      }
      mapEncoder.setElement(name, member);
    });
  }

  /// Serialize the source position of [element] into [encoder].
  static void serializePosition(Element element, ObjectEncoder encoder) {
    if (element.sourcePosition != null) {
      SourceSpan position = element.sourcePosition;
      encoder.setInt(Key.OFFSET, position.begin);
      if (position.uri != element.compilationUnit.script.resourceUri) {
        // TODO(johnniwinther): What is the base URI in the case?
        encoder.setUri(Key.URI, element.library.canonicalUri, position.uri);
      }
      int length = position.end - position.begin;
      if (element.name.length != length) {
        encoder.setInt(Key.LENGTH, length);
      }
    }
  }

  /// Serialize the parameters of [element] into [encoder].
  static void serializeParameters(FunctionElement element,
                                  ObjectEncoder encoder) {
    FunctionType type = element.type;
    encoder.setType(Key.RETURN_TYPE, type.returnType);
    encoder.setElements(Key.PARAMETERS, element.parameters);
  }

  /// Returns a function that adds the underlying declared elements for a
  /// particular element into [list].
  ///
  /// For instance, for an [AbstractFieldElement] the getter and setter elements
  /// are added, if available.
  static flattenElements(List<Element> list) {
    return (Element element) {
      // TODO(johnniwinther): Handle ambiguous elements.
      if (element.isAmbiguous) return;
      if (element.isAbstractField) {
        AbstractFieldElement abstractField = element;
        if (abstractField.getter != null) {
          list.add(abstractField.getter);
        }
        if (abstractField.setter != null) {
          list.add(abstractField.setter);
        }
      } else {
        list.add(element);
      }
    };
  }
}

class LibrarySerializer implements ElementSerializer {
  const LibrarySerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isLibrary) {
      return SerializedElementKind.LIBRARY;
    }
    return null;
  }

  void serialize(LibraryElement element,
                 ObjectEncoder encoder,
                 SerializedElementKind kind) {
    encoder.setUri(
        Key.CANONICAL_URI, element.canonicalUri, element.canonicalUri);
    encoder.setString(Key.LIBRARY_NAME, element.libraryName);
    SerializerUtil.serializeMembers(element, encoder);
    encoder.setElement(Key.COMPILATION_UNIT, element.entryCompilationUnit);
    encoder.setElements(
        Key.COMPILATION_UNITS, element.compilationUnits.toList());
    encoder.setElements(Key.IMPORTS, element.imports);
    encoder.setElements(Key.EXPORTS, element.exports);

    List<Element> importedElements = <Element>[];
    element.forEachImport(SerializerUtil.flattenElements(importedElements));
    encoder.setElements(Key.IMPORT_SCOPE, importedElements);

    List<Element> exportedElements = <Element>[];
    element.forEachExport(SerializerUtil.flattenElements(exportedElements));
    encoder.setElements(Key.EXPORT_SCOPE, exportedElements);

  }
}

class CompilationUnitSerializer implements ElementSerializer {
  const CompilationUnitSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isCompilationUnit) {
      return SerializedElementKind.COMPILATION_UNIT;
    }
    return null;
  }

  void serialize(CompilationUnitElement element,
                 ObjectEncoder encoder,
                 SerializedElementKind kind) {
    encoder.setElement(Key.LIBRARY, element.library);
    encoder.setUri(
        Key.URI, element.library.canonicalUri, element.script.resourceUri);
    List<Element> elements = <Element>[];
    element.forEachLocalMember((e) => elements.add(e));
    encoder.setElements(Key.ELEMENTS, elements);
  }
}

class ClassSerializer implements ElementSerializer {
  const ClassSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isClass) {
      return SerializedElementKind.CLASS;
    }
    return null;
  }

  void serialize(ClassElement element,
                 ObjectEncoder encoder,
                 SerializedElementKind kind) {
    encoder.setElement(Key.LIBRARY, element.library);
    encoder.setElement(Key.COMPILATION_UNIT, element.compilationUnit);
    encoder.setString(Key.NAME, element.name);
    SerializerUtil.serializePosition(element, encoder);
    encoder.setTypes(Key.TYPE_VARIABLES, element.typeVariables);
    encoder.setBool(Key.IS_ABSTRACT, element.isAbstract);
    if (element.supertype != null) {
      encoder.setType(Key.SUPERTYPE, element.supertype);
    }
    // TODO(johnniwinther): Make [OrderedTypeSet] easier to (de)serialize.
    ObjectEncoder supertypes = encoder.createObject(Key.SUPERTYPES);
    supertypes.setTypes(Key.TYPES,
        element.allSupertypesAndSelf.types.toList());
    supertypes.setTypes(Key.SUPERTYPES,
        element.allSupertypesAndSelf.supertypes.toList());
    supertypes.setInts(Key.OFFSETS, element.allSupertypesAndSelf.levelOffsets);
    encoder.setTypes(Key.INTERFACES, element.interfaces.toList());
    SerializerUtil.serializeMembers(element, encoder);
  }
}

class ConstructorSerializer implements ElementSerializer {
  const ConstructorSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isGenerativeConstructor) {
      return SerializedElementKind.GENERATIVE_CONSTRUCTOR;
    } else if (element.isFactoryConstructor) {
      return SerializedElementKind.FACTORY_CONSTRUCTOR;
    }
    return null;
  }

  void serialize(ConstructorElement element,
                 ObjectEncoder encoder,
                 SerializedElementKind kind) {
    encoder.setElement(Key.CLASS, element.enclosingClass);
    encoder.setType(Key.TYPE, element.type);
    encoder.setString(Key.NAME, element.name);
    SerializerUtil.serializePosition(element, encoder);
    SerializerUtil.serializeParameters(element, encoder);
    encoder.setBool(Key.IS_CONST, element.isConst);
    // TODO(johnniwinther): Handle external constructors.
    encoder.setBool(Key.IS_EXTERNAL, element.isExternal);
    if (element.isExternal) return;
    if (element.isConst && !element.isFromEnvironmentConstructor) {
      ConstantConstructor constantConstructor = element.constantConstructor;
      ObjectEncoder constantEncoder =
          encoder.createObject(Key.CONSTRUCTOR);
      const ConstantConstructorSerializer().visit(
          constantConstructor, constantEncoder);
    }
  }
}

class FieldSerializer implements ElementSerializer {
  const FieldSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isField) {
      if (element.isTopLevel) return SerializedElementKind.TOPLEVEL_FIELD;
      if (element.isStatic) return SerializedElementKind.STATIC_FIELD;
      if (element.isInstanceMember) return SerializedElementKind.INSTANCE_FIELD;
    }
    return null;
  }

  void serialize(FieldElement element,
                 ObjectEncoder encoder,
                 SerializedElementKind kind) {
    encoder.setString(Key.NAME, element.name);
    SerializerUtil.serializePosition(element, encoder);
    encoder.setType(Key.TYPE, element.type);
    encoder.setBool(Key.IS_FINAL, element.isFinal);
    encoder.setBool(Key.IS_CONST, element.isConst);
    if (element.isConst) {
      ConstantExpression constant = element.constant;
      encoder.setConstant(Key.CONSTANT, constant);
    }
    if (kind != SerializedElementKind.TOPLEVEL_FIELD) {
      encoder.setElement(Key.CLASS, element.enclosingClass);
    } else {
      encoder.setElement(Key.LIBRARY, element.library);
      encoder.setElement(Key.COMPILATION_UNIT, element.compilationUnit);
    }
  }
}

class FunctionSerializer implements ElementSerializer {
  const FunctionSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isFunction) {
      if (element.isTopLevel) return SerializedElementKind.TOPLEVEL_FUNCTION;
      if (element.isStatic) return SerializedElementKind.STATIC_FUNCTION;
      if (element.isInstanceMember) {
        return SerializedElementKind.INSTANCE_FUNCTION;
      }
    }
    if (element.isGetter) {
      if (element.isTopLevel) return SerializedElementKind.TOPLEVEL_GETTER;
      if (element.isStatic) return SerializedElementKind.STATIC_GETTER;
      if (element.isInstanceMember) {
        return SerializedElementKind.INSTANCE_GETTER;
      }
    }
    if (element.isSetter) {
      if (element.isTopLevel) return SerializedElementKind.TOPLEVEL_SETTER;
      if (element.isStatic) return SerializedElementKind.STATIC_SETTER;
      if (element.isInstanceMember) {
        return SerializedElementKind.INSTANCE_SETTER;
      }
    }
    return null;
  }

  void serialize(FunctionElement element,
                 ObjectEncoder encoder,
                 SerializedElementKind kind) {
    encoder.setString(Key.NAME, element.name);
    SerializerUtil.serializePosition(element, encoder);
    SerializerUtil.serializeParameters(element, encoder);
    encoder.setType(Key.TYPE, element.type);
    if (element.isFunction) {
      encoder.setBool(Key.IS_OPERATOR, element.isOperator);
    }
    if (element.enclosingClass != null) {
      encoder.setElement(Key.CLASS, element.enclosingClass);
    } else {
      encoder.setElement(Key.LIBRARY, element.library);
      encoder.setElement(Key.COMPILATION_UNIT, element.compilationUnit);
    }
  }
}

class TypedefSerializer implements ElementSerializer {
  const TypedefSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isTypedef) {
      return SerializedElementKind.TYPEDEF;
    }
    return null;
  }

  void serialize(TypedefElement element,
                 ObjectEncoder encoder,
                 SerializedElementKind kind) {
    encoder.setString(Key.NAME, element.name);
    SerializerUtil.serializePosition(element, encoder);
    encoder.setType(Key.ALIAS, element.alias);
    encoder.setElement(Key.LIBRARY, element.library);
    encoder.setTypes(Key.TYPE_VARIABLES, element.typeVariables);
    encoder.setElement(Key.COMPILATION_UNIT, element.compilationUnit);
  }
}

class TypeVariableSerializer implements ElementSerializer {
  const TypeVariableSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isTypeVariable) {
      return SerializedElementKind.TYPEVARIABLE;
    }
    return null;
  }

  void serialize(TypeVariableElement element,
                 ObjectEncoder encoder,
                 SerializedElementKind kind) {
    encoder.setElement(Key.TYPE_DECLARATION, element.typeDeclaration);
    encoder.setString(Key.NAME, element.name);
    SerializerUtil.serializePosition(element, encoder);
    encoder.setType(Key.TYPE, element.type);
    encoder.setInt(Key.INDEX, element.index);
    encoder.setType(Key.BOUND, element.bound);
  }
}

class ParameterSerializer implements ElementSerializer {
  const ParameterSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isParameter) {
      return SerializedElementKind.PARAMETER;
    } else if (element.isInitializingFormal) {
      return SerializedElementKind.INITIALIZING_FORMAL;
    }
    return null;
  }

  void serialize(ParameterElement element,
                 ObjectEncoder encoder,
                 SerializedElementKind kind) {
    encoder.setElement(Key.FUNCTION, element.functionDeclaration);
    encoder.setString(Key.NAME, element.name);
    SerializerUtil.serializePosition(element, encoder);
    encoder.setType(Key.TYPE, element.type);
    encoder.setBool(Key.IS_OPTIONAL, element.isOptional);
    encoder.setBool(Key.IS_NAMED, element.isNamed);
    if (element.isOptional) {
      encoder.setConstant(Key.CONSTANT, element.constant);
    }
    if (element.isInitializingFormal) {
      InitializingFormalElement initializingFormal = element;
      encoder.setElement(Key.FIELD, initializingFormal.fieldElement);
    }
  }
}

class ImportSerializer implements ElementSerializer {
  const ImportSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isImport) {
      return SerializedElementKind.IMPORT;
    }
    return null;
  }

  void serialize(ImportElement element,
                 ObjectEncoder encoder,
                 SerializedElementKind kind) {
    encoder.setElement(Key.LIBRARY, element.library);
    encoder.setElement(Key.COMPILATION_UNIT, element.compilationUnit);
    encoder.setElement(Key.LIBRARY_DEPENDENCY, element.importedLibrary);
    if (element.prefix != null) {
      encoder.setElement(Key.PREFIX, element.prefix);
    }
    encoder.setBool(Key.IS_DEFERRED, element.isDeferred);
    // TODO(johnniwinther): What is the base for the URI?
    encoder.setUri(Key.URI, element.uri, element.uri);
  }
}

class ExportSerializer implements ElementSerializer {
  const ExportSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isExport) {
      return SerializedElementKind.EXPORT;
    }
    return null;
  }

  void serialize(ExportElement element,
                 ObjectEncoder encoder,
                 SerializedElementKind kind) {
    encoder.setElement(Key.LIBRARY, element.library);
    encoder.setElement(Key.COMPILATION_UNIT, element.compilationUnit);
    encoder.setElement(Key.LIBRARY_DEPENDENCY, element.exportedLibrary);
    // TODO(johnniwinther): What is the base for the URI?
    encoder.setUri(Key.URI, element.uri, element.uri);
  }
}

class PrefixSerializer implements ElementSerializer {
  const PrefixSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isPrefix) {
      return SerializedElementKind.PREFIX;
    }
    return null;
  }

  void serialize(PrefixElement element,
                 ObjectEncoder encoder,
                 SerializedElementKind kind) {
    encoder.setString(Key.NAME, element.name);
    encoder.setElement(Key.LIBRARY, element.library);
    encoder.setElement(Key.COMPILATION_UNIT, element.compilationUnit);
    if (element.deferredImport != null) {
      encoder.setElement(Key.IMPORT, element.deferredImport);
    }
    encoder.setBool(Key.IS_DEFERRED, element.isDeferred);
  }
}

/// Utility class for deserializing [Element]s.
///
/// This is used by the [Deserializer].
class ElementDeserializer {

  /// Deserializes an [Element] from an [ObjectDecoder].
  ///
  /// The class is called from the [Deserializer] when an [Element]
  /// needs deserialization. The [ObjectDecoder] ensures that any [Element],
  /// [DartType], and [ConstantExpression] that the deserialized [Element]
  /// depends upon are available.
  static Element deserialize(ObjectDecoder decoder) {
    SerializedElementKind elementKind =
        decoder.getEnum(Key.KIND, SerializedElementKind.values);
    switch (elementKind) {
      case SerializedElementKind.LIBRARY:
        return new LibraryElementZ(decoder);
      case SerializedElementKind.COMPILATION_UNIT:
        return new CompilationUnitElementZ(decoder);
      case SerializedElementKind.CLASS:
        return new ClassElementZ(decoder);
      case SerializedElementKind.TOPLEVEL_FIELD:
        return new TopLevelFieldElementZ(decoder);
      case SerializedElementKind.STATIC_FIELD:
        return new StaticFieldElementZ(decoder);
      case SerializedElementKind.INSTANCE_FIELD:
        return new InstanceFieldElementZ(decoder);
      case SerializedElementKind.GENERATIVE_CONSTRUCTOR:
        return new GenerativeConstructorElementZ(decoder);
      case SerializedElementKind.FACTORY_CONSTRUCTOR:
        return new FactoryConstructorElementZ(decoder);
      case SerializedElementKind.TOPLEVEL_FUNCTION:
        return new TopLevelFunctionElementZ(decoder);
      case SerializedElementKind.STATIC_FUNCTION:
        return new StaticFunctionElementZ(decoder);
      case SerializedElementKind.INSTANCE_FUNCTION:
        return new InstanceFunctionElementZ(decoder);
      case SerializedElementKind.TOPLEVEL_GETTER:
        return new TopLevelGetterElementZ(decoder);
      case SerializedElementKind.STATIC_GETTER:
        return new StaticGetterElementZ(decoder);
      case SerializedElementKind.INSTANCE_GETTER:
        return new InstanceGetterElementZ(decoder);
      case SerializedElementKind.TOPLEVEL_SETTER:
        return new TopLevelSetterElementZ(decoder);
      case SerializedElementKind.STATIC_SETTER:
        return new StaticSetterElementZ(decoder);
      case SerializedElementKind.INSTANCE_SETTER:
        return new InstanceSetterElementZ(decoder);
      case SerializedElementKind.TYPEDEF:
        return new TypedefElementZ(decoder);
      case SerializedElementKind.TYPEVARIABLE:
        return new TypeVariableElementZ(decoder);
      case SerializedElementKind.PARAMETER:
        return new ParameterElementZ(decoder);
      case SerializedElementKind.INITIALIZING_FORMAL:
        return new InitializingFormalElementZ(decoder);
      case SerializedElementKind.IMPORT:
        return new ImportElementZ(decoder);
      case SerializedElementKind.EXPORT:
        return new ExportElementZ(decoder);
      case SerializedElementKind.PREFIX:
        return new PrefixElementZ(decoder);
    }
    throw new UnsupportedError("Unexpected element kind '${elementKind}.");
  }
}