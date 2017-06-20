// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.elements;

import '../common.dart';
import '../constants/constructors.dart';
import '../constants/expressions.dart';
import '../elements/resolution_types.dart';
import '../diagnostics/messages.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart'
    show
        AmbiguousImportX,
        DeferredLoaderGetterElementX,
        ErroneousElementX,
        WarnOnUseElementX,
        WrappedMessage;
import 'constant_serialization.dart';
import 'keys.dart';
import 'modelz.dart';
import 'serialization.dart';
import 'serialization_util.dart';

/// Enum kinds used for encoding [Element]s.
enum SerializedElementKind {
  ERROR,
  LIBRARY,
  COMPILATION_UNIT,
  CLASS,
  ENUM,
  NAMED_MIXIN_APPLICATION,
  GENERATIVE_CONSTRUCTOR,
  DEFAULT_CONSTRUCTOR,
  FACTORY_CONSTRUCTOR,
  REDIRECTING_FACTORY_CONSTRUCTOR,
  FORWARDING_CONSTRUCTOR,
  TOPLEVEL_FIELD,
  STATIC_FIELD,
  INSTANCE_FIELD,
  ENUM_CONSTANT,
  TOPLEVEL_FUNCTION,
  TOPLEVEL_GETTER,
  TOPLEVEL_SETTER,
  STATIC_FUNCTION,
  STATIC_GETTER,
  STATIC_SETTER,
  INSTANCE_FUNCTION,
  INSTANCE_GETTER,
  INSTANCE_SETTER,
  LOCAL_FUNCTION,
  TYPEDEF,
  TYPEVARIABLE,
  PARAMETER,
  INITIALIZING_FORMAL,
  IMPORT,
  EXPORT,
  PREFIX,
  DEFERRED_LOAD_LIBRARY,
  LOCAL_VARIABLE,
  WARN_ON_USE,
  AMBIGUOUS,
  EXTERNAL_LIBRARY,
  EXTERNAL_LIBRARY_MEMBER,
  EXTERNAL_CLASS_MEMBER,
  EXTERNAL_CONSTRUCTOR,
}

/// Set of serializers used to serialize different kinds of elements by
/// encoding into them into [ObjectEncoder]s.
///
/// This class is called from the [Serializer] when an [Element] needs
/// serialization. The [ObjectEncoder] ensures that any [Element],
/// [ResolutionDartType], and [ConstantExpression] that the serialized [Element]
/// depends upon are also serialized.
const List<ElementSerializer> ELEMENT_SERIALIZERS = const [
  const ErrorSerializer(),
  const LibrarySerializer(),
  const CompilationUnitSerializer(),
  const PrefixSerializer(),
  const DeferredLoadLibrarySerializer(),
  const ClassSerializer(),
  const ConstructorSerializer(),
  const FieldSerializer(),
  const FunctionSerializer(),
  const TypedefSerializer(),
  const TypeVariableSerializer(),
  const ParameterSerializer(),
  const ImportSerializer(),
  const ExportSerializer(),
  const LocalVariableSerializer(),
  const WarnOnUseSerializer(),
  const AmbiguousSerializer(),
];

/// Interface for a function that can serialize a set of element kinds.
abstract class ElementSerializer {
  /// Returns the [SerializedElementKind] for [element] if this serializer
  /// supports serialization of [element] or `null` otherwise.
  SerializedElementKind getSerializedKind(Element element);

  /// Serializes [element] into the [encoder] using the [kind] computed
  /// by [getSerializedKind].
  void serialize(covariant Element element, ObjectEncoder encoder,
      SerializedElementKind kind);
}

class SerializerUtil {
  /// Serialize the declared members of [element] into [encoder].
  static void serializeMembers(
      Iterable<Element> members, ObjectEncoder encoder) {
    MapEncoder mapEncoder = encoder.createMap(Key.MEMBERS);
    for (Element member in members) {
      String name = member.name;
      if (member.isSetter) {
        name = '$name,=';
      }
      mapEncoder.setElement(name, member);
    }
  }

  /// Serialize the source position of [element] into [encoder].
  static void serializePosition(Element element, ObjectEncoder encoder) {
    if (element.sourcePosition != null) {
      SourceSpan position = element.sourcePosition;
      encoder.setInt(Key.OFFSET, position.begin);
      // TODO(johnniwinther): What is the base URI in the case?
      if (position.uri != element.compilationUnit.script.resourceUri) {
        encoder.setUri(Key.URI, element.library.canonicalUri, position.uri);
      }
      int length = position.end - position.begin;
      if (element.name.length != length) {
        encoder.setInt(Key.LENGTH, length);
      }
    }
  }

  /// Serialize the metadata of [element] into [encoder].
  static void serializeMetadata(Element element, ObjectEncoder encoder) {
    ListEncoder list;

    void encodeAnnotation(MetadataAnnotation metadata) {
      ObjectEncoder object = list.createObject();
      object.setElement(Key.ELEMENT, metadata.annotatedElement);
      SourceSpan sourcePosition = metadata.sourcePosition;
      // TODO(johnniwinther): What is the base URI here?
      object.setUri(Key.URI, sourcePosition.uri, sourcePosition.uri);
      object.setInt(Key.OFFSET, sourcePosition.begin);
      object.setInt(Key.LENGTH, sourcePosition.end - sourcePosition.begin);
      object.setConstant(Key.CONSTANT, metadata.constant);
    }

    if (element.metadata.isNotEmpty) {
      list = encoder.createList(Key.METADATA);
      element.metadata.forEach(encodeAnnotation);
    }
    if (element.isPatched && element.implementation.metadata.isNotEmpty) {
      list ??= encoder.createList(Key.METADATA);
      element.implementation.metadata.forEach(encodeAnnotation);
    }
  }

  /// Serialize the parent relation for [element] into [encoder], i.e library,
  /// enclosing class, and compilation unit references.
  static void serializeParentRelation(Element element, ObjectEncoder encoder) {
    if (element.enclosingClass != null) {
      encoder.setElement(Key.CLASS, element.enclosingClass);
      if (element.enclosingClass.compilationUnit != element.compilationUnit) {
        encoder.setElement(Key.COMPILATION_UNIT, element.compilationUnit);
      }
    } else {
      encoder.setElement(Key.LIBRARY, element.library);
      encoder.setElement(Key.COMPILATION_UNIT, element.compilationUnit);
    }
  }

  /// Serialize the parameters of [element] into [encoder].
  static void serializeParameters(
      FunctionElement element, ObjectEncoder encoder) {
    ResolutionFunctionType type = element.type;
    encoder.setType(Key.RETURN_TYPE, type.returnType);
    encoder.setElements(Key.PARAMETERS, element.parameters);
  }

  /// Returns a function that adds the underlying declared elements for a
  /// particular element into [set].
  ///
  /// For instance, for an [AbstractFieldElement] the getter and setter elements
  /// are added, if available.
  static flattenElements(Set<Element> set) {
    return (Element element) {
      if (element.isPatch) return;
      // TODO(johnniwinther): Handle ambiguous elements.
      if (element.isAmbiguous) return;
      if (element.isAbstractField) {
        AbstractFieldElement abstractField = element;
        if (abstractField.getter != null) {
          set.add(abstractField.getter);
        }
        if (abstractField.setter != null) {
          set.add(abstractField.setter);
        }
      } else {
        set.add(element);
      }
    };
  }
}

class ErrorSerializer implements ElementSerializer {
  const ErrorSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isError) {
      return SerializedElementKind.ERROR;
    }
    return null;
  }

  void serialize(ErroneousElement element, ObjectEncoder encoder,
      SerializedElementKind kind) {
    encoder.setElement(Key.ENCLOSING, element.enclosingElement);
    encoder.setString(Key.NAME, element.name);
    encoder.setEnum(Key.MESSAGE_KIND, element.messageKind);
    serializeMessageArguments(encoder, Key.ARGUMENTS, element.messageArguments);
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

  static List<Element> getMembers(LibraryElement element) {
    List<Element> members = <Element>[];
    element.implementation.forEachLocalMember((Element member) {
      if (!member.isPatch) {
        members.add(member);
      }
    });
    return members;
  }

  static List<CompilationUnitElement> getCompilationUnits(
      LibraryElement element) {
    List<CompilationUnitElement> compilationUnits = <CompilationUnitElement>[];
    compilationUnits.addAll(element.compilationUnits.toList());
    if (element.isPatched) {
      compilationUnits.addAll(element.implementation.compilationUnits.toList());
    }
    return compilationUnits;
  }

  static List<ImportElement> getImports(LibraryElement element) {
    List<ImportElement> imports = <ImportElement>[];
    imports.addAll(element.imports);
    if (element.isPatched) {
      imports.addAll(element.implementation.imports);
    }
    return imports;
  }

  static List<Element> getImportedElements(LibraryElement element) {
    Set<Element> importedElements = new Set<Element>();
    element.forEachImport(SerializerUtil.flattenElements(importedElements));
    if (element.isPatched) {
      element.implementation
          .forEachImport(SerializerUtil.flattenElements(importedElements));
    }
    return importedElements.toList();
  }

  static List<Element> getExportedElements(LibraryElement element) {
    Set<Element> exportedElements = new Set<Element>();
    element.forEachExport(SerializerUtil.flattenElements(exportedElements));
    return exportedElements.toList();
  }

  void serialize(LibraryElement element, ObjectEncoder encoder,
      SerializedElementKind kind) {
    SerializerUtil.serializeMetadata(element, encoder);
    encoder.setUri(
        Key.CANONICAL_URI, element.canonicalUri, element.canonicalUri);
    encoder.setString(Key.LIBRARY_NAME, element.libraryName);
    SerializerUtil.serializeMembers(getMembers(element), encoder);
    encoder.setElement(Key.COMPILATION_UNIT, element.entryCompilationUnit);
    encoder.setElements(Key.COMPILATION_UNITS, getCompilationUnits(element));
    encoder.setElements(Key.IMPORTS, getImports(element));
    encoder.setElements(Key.EXPORTS, element.exports);

    List<Element> importedElements = getImportedElements(element);
    encoder.setElements(Key.IMPORT_SCOPE, importedElements);
    encoder.setElements(Key.EXPORT_SCOPE, getExportedElements(element));

    Map<Element, Iterable<ImportElement>> importsForMap =
        <Element, Iterable<ImportElement>>{};

    /// Map imports for [importedElement] in importsForMap.
    ///
    /// Imports are mapped to [AbstractFieldElement] which are not serialized
    /// so we use getter (or setter if there is no getter) as the key.
    void addImportsForElement(Element importedElement) {
      Element key = importedElement;
      if (importedElement.isDeferredLoaderGetter) {
        // Use [importedElement].
      } else if (importedElement.isGetter) {
        GetterElement getter = importedElement;
        importedElement = getter.abstractField;
      } else if (importedElement.isSetter) {
        SetterElement setter = importedElement;
        if (setter.getter != null) {
          return;
        }
        importedElement = setter.abstractField;
      }
      importsForMap.putIfAbsent(
          key, () => element.getImportsFor(importedElement));
    }

    for (ImportElement import in getImports(element)) {
      if (import.prefix != null) {
        Set<Element> importedElements = new Set<Element>();
        import.prefix.forEachLocalMember(
            SerializerUtil.flattenElements(importedElements));
        importedElements.forEach(addImportsForElement);
      }
    }
    importedElements.forEach(addImportsForElement);

    ListEncoder importsForEncoder = encoder.createList(Key.IMPORTS_FOR);
    importsForMap
        .forEach((Element importedElement, Iterable<ImportElement> imports) {
      ObjectEncoder objectEncoder = importsForEncoder.createObject();
      objectEncoder.setElement(Key.ELEMENT, importedElement);
      objectEncoder.setElements(Key.IMPORTS, imports);
    });
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

  void serialize(CompilationUnitElement element, ObjectEncoder encoder,
      SerializedElementKind kind) {
    SerializerUtil.serializeMetadata(element, encoder);
    encoder.setElement(Key.LIBRARY, element.library);
    encoder.setUri(
        Key.URI, element.library.canonicalUri, element.script.resourceUri);
    List<Element> elements = <Element>[];
    element.forEachLocalMember((e) {
      if (!element.isPatch) {
        elements.add(e);
      }
    });
    encoder.setElements(Key.ELEMENTS, elements);
  }
}

class ClassSerializer implements ElementSerializer {
  const ClassSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isClass) {
      ClassElement cls = element;
      if (cls.isEnumClass) {
        return SerializedElementKind.ENUM;
      } else if (cls.isMixinApplication) {
        if (!cls.isUnnamedMixinApplication) {
          return SerializedElementKind.NAMED_MIXIN_APPLICATION;
        }
      } else {
        return SerializedElementKind.CLASS;
      }
    }
    return null;
  }

  static List<Element> getMembers(ClassElement element) {
    List<Element> members = <Element>[];
    element.forEachLocalMember(members.add);
    if (element.isPatched) {
      element.implementation.forEachLocalMember((Element member) {
        if (!member.isPatch) {
          members.add(member);
        }
      });
    }
    return members;
  }

  void serialize(
      ClassElement element, ObjectEncoder encoder, SerializedElementKind kind) {
    SerializerUtil.serializeMetadata(element, encoder);
    encoder.setElement(Key.LIBRARY, element.library);
    encoder.setElement(Key.COMPILATION_UNIT, element.compilationUnit);
    encoder.setString(Key.NAME, element.name);
    SerializerUtil.serializePosition(element, encoder);
    encoder.setTypes(Key.TYPE_VARIABLES, element.typeVariables);
    encoder.setBool(Key.IS_ABSTRACT, element.isAbstract);
    SerializerUtil.serializeMembers(getMembers(element), encoder);
    encoder.setBool(Key.IS_PROXY, element.isProxy);
    encoder.setBool(Key.IS_INJECTED, element.isInjected);
    if (kind == SerializedElementKind.ENUM) {
      EnumClassElement enumClass = element;
      encoder.setElements(Key.FIELDS, enumClass.enumValues);
    }
    if (element.isObject) return;

    List<ResolutionInterfaceType> mixins = <ResolutionInterfaceType>[];
    ClassElement superclass = element.superclass;
    while (superclass.isUnnamedMixinApplication) {
      MixinApplicationElement mixinElement = superclass;
      mixins.add(element.thisType.asInstanceOf(mixinElement.mixin));
      superclass = mixinElement.superclass;
    }
    mixins = mixins.reversed.toList();
    ResolutionInterfaceType supertype =
        element.thisType.asInstanceOf(superclass);

    encoder.setType(Key.SUPERTYPE, supertype);
    encoder.setTypes(Key.MIXINS, mixins);
    encoder.setTypes(Key.INTERFACES, element.interfaces.toList());
    ResolutionFunctionType callType = element.declaration.callType;
    if (callType != null) {
      encoder.setType(Key.CALL_TYPE, element.callType);
    }

    if (element.isMixinApplication) {
      MixinApplicationElement mixinElement = element;
      encoder.setType(Key.MIXIN, mixinElement.mixinType);
    }
  }
}

class ConstructorSerializer implements ElementSerializer {
  const ConstructorSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isGenerativeConstructor) {
      ConstructorElement constructor = element;
      if (constructor.enclosingClass.isNamedMixinApplication) {
        return SerializedElementKind.FORWARDING_CONSTRUCTOR;
      } else if (constructor.definingConstructor != null) {
        return SerializedElementKind.DEFAULT_CONSTRUCTOR;
      } else {
        return SerializedElementKind.GENERATIVE_CONSTRUCTOR;
      }
    } else if (element.isFactoryConstructor) {
      ConstructorElement constructor = element;
      if (constructor.isRedirectingFactory) {
        return SerializedElementKind.REDIRECTING_FACTORY_CONSTRUCTOR;
      } else {
        return SerializedElementKind.FACTORY_CONSTRUCTOR;
      }
    }
    return null;
  }

  void serialize(ConstructorElement element, ObjectEncoder encoder,
      SerializedElementKind kind) {
    SerializerUtil.serializeParentRelation(element, encoder);
    if (kind == SerializedElementKind.FORWARDING_CONSTRUCTOR) {
      serializeElementReference(element.enclosingClass, Key.ELEMENT, Key.NAME,
          encoder, element.definingConstructor);
    } else {
      SerializerUtil.serializeMetadata(element, encoder);
      encoder.setType(Key.TYPE, element.type);
      encoder.setString(Key.NAME, element.name);
      SerializerUtil.serializePosition(element, encoder);
      SerializerUtil.serializeParameters(element, encoder);
      encoder.setBool(Key.IS_CONST, element.isConst);
      encoder.setBool(Key.IS_EXTERNAL, element.isExternal);
      encoder.setBool(Key.IS_INJECTED, element.isInjected);
      if (element.isConst && !element.isFromEnvironmentConstructor) {
        ConstantConstructor constantConstructor = element.constantConstructor;
        ObjectEncoder constantEncoder = encoder.createObject(Key.CONSTRUCTOR);
        const ConstantConstructorSerializer()
            .visit(constantConstructor, constantEncoder);
      }
      if (kind == SerializedElementKind.GENERATIVE_CONSTRUCTOR) {
        encoder.setBool(Key.IS_REDIRECTING, element.isRedirectingGenerative);
      }
      encoder.setElement(Key.EFFECTIVE_TARGET, element.effectiveTarget);
      if (kind == SerializedElementKind.REDIRECTING_FACTORY_CONSTRUCTOR) {
        encoder.setType(
            Key.EFFECTIVE_TARGET_TYPE,
            element
                .computeEffectiveTargetType(element.enclosingClass.thisType));
        encoder.setElement(Key.IMMEDIATE_REDIRECTION_TARGET,
            element.immediateRedirectionTarget);
        encoder.setBool(Key.EFFECTIVE_TARGET_IS_MALFORMED,
            element.isEffectiveTargetMalformed);
        if (element.redirectionDeferredPrefix != null) {
          encoder.setElement(Key.PREFIX, element.redirectionDeferredPrefix);
        }
      }
    }
  }
}

class FieldSerializer implements ElementSerializer {
  const FieldSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isField) {
      if (element.isTopLevel) return SerializedElementKind.TOPLEVEL_FIELD;
      if (element.isStatic) {
        if (element is EnumConstantElement) {
          return SerializedElementKind.ENUM_CONSTANT;
        }
        return SerializedElementKind.STATIC_FIELD;
      }
      if (element.isInstanceMember) return SerializedElementKind.INSTANCE_FIELD;
    }
    return null;
  }

  void serialize(
      FieldElement element, ObjectEncoder encoder, SerializedElementKind kind) {
    encoder.setString(Key.NAME, element.name);
    SerializerUtil.serializeMetadata(element, encoder);
    SerializerUtil.serializePosition(element, encoder);
    encoder.setType(Key.TYPE, element.type);
    encoder.setBool(Key.IS_FINAL, element.isFinal);
    encoder.setBool(Key.IS_CONST, element.isConst);
    encoder.setBool(Key.IS_INJECTED, element.isInjected);
    ConstantExpression constant = element.constant;
    if (constant != null) {
      encoder.setConstant(Key.CONSTANT, constant);
    }
    SerializerUtil.serializeParentRelation(element, encoder);
    if (element is EnumConstantElement) {
      EnumConstantElement enumConstant = element;
      encoder.setInt(Key.INDEX, enumConstant.index);
    }
  }
}

class FunctionSerializer implements ElementSerializer {
  const FunctionSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isDeferredLoaderGetter) {
      return null;
    }
    if (element.isFunction) {
      if (element.isTopLevel) return SerializedElementKind.TOPLEVEL_FUNCTION;
      if (element.isStatic) return SerializedElementKind.STATIC_FUNCTION;
      if (element.isInstanceMember) {
        return SerializedElementKind.INSTANCE_FUNCTION;
      }
      if (element.isLocal) {
        return SerializedElementKind.LOCAL_FUNCTION;
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

  void serialize(FunctionElement element, ObjectEncoder encoder,
      SerializedElementKind kind) {
    encoder.setString(Key.NAME, element.name);
    SerializerUtil.serializeMetadata(element, encoder);
    SerializerUtil.serializePosition(element, encoder);
    SerializerUtil.serializeParameters(element, encoder);
    encoder.setType(Key.TYPE, element.type);
    if (element.isFunction) {
      encoder.setBool(Key.IS_OPERATOR, element.isOperator);
      encoder.setEnum(Key.ASYNC_MARKER, element.asyncMarker);
    } else if (element.isGetter) {
      encoder.setEnum(Key.ASYNC_MARKER, element.asyncMarker);
    }
    SerializerUtil.serializeParentRelation(element, encoder);
    encoder.setBool(Key.IS_EXTERNAL, element.isExternal);
    encoder.setBool(Key.IS_ABSTRACT, element.isAbstract);
    encoder.setBool(Key.IS_INJECTED, element.isInjected);
    if (element.isLocal) {
      LocalFunctionElement localFunction = element;
      encoder.setElement(
          Key.EXECUTABLE_CONTEXT, localFunction.executableContext);
    }
    encoder.setTypes(Key.TYPE_VARIABLES, element.typeVariables);
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

  void serialize(TypedefElement element, ObjectEncoder encoder,
      SerializedElementKind kind) {
    encoder.setString(Key.NAME, element.name);
    SerializerUtil.serializeMetadata(element, encoder);
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

  void serialize(TypeVariableElement element, ObjectEncoder encoder,
      SerializedElementKind kind) {
    encoder.setElement(Key.TYPE_DECLARATION, element.typeDeclaration);
    encoder.setString(Key.NAME, element.name);
    SerializerUtil.serializeMetadata(element, encoder);
    SerializerUtil.serializePosition(element, encoder);
    encoder.setType(Key.TYPE, element.type);
    encoder.setInt(Key.INDEX, element.index);
    encoder.setType(Key.BOUND, element.bound);
  }
}

class ParameterSerializer implements ElementSerializer {
  const ParameterSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isRegularParameter) {
      return SerializedElementKind.PARAMETER;
    } else if (element.isInitializingFormal) {
      return SerializedElementKind.INITIALIZING_FORMAL;
    }
    return null;
  }

  void serialize(ParameterElement element, ObjectEncoder encoder,
      SerializedElementKind kind) {
    encoder.setElement(Key.FUNCTION, element.functionDeclaration);
    encoder.setString(Key.NAME, element.name);
    SerializerUtil.serializeMetadata(element, encoder);
    SerializerUtil.serializePosition(element, encoder);
    encoder.setType(Key.TYPE, element.type);
    encoder.setBool(Key.IS_OPTIONAL, element.isOptional);
    encoder.setBool(Key.IS_NAMED, element.isNamed);
    encoder.setBool(Key.IS_FINAL, element.isFinal);
    if (element.isOptional) {
      encoder.setConstant(Key.CONSTANT, element.constant);
    }
    if (element.isInitializingFormal) {
      InitializingFormalElement initializingFormal = element;
      encoder.setElement(Key.FIELD, initializingFormal.fieldElement);
    }
  }
}

class LocalVariableSerializer implements ElementSerializer {
  const LocalVariableSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isVariable) {
      return SerializedElementKind.LOCAL_VARIABLE;
    }
    return null;
  }

  void serialize(LocalVariableElement element, ObjectEncoder encoder,
      SerializedElementKind kind) {
    encoder.setString(Key.NAME, element.name);
    SerializerUtil.serializeMetadata(element, encoder);
    SerializerUtil.serializePosition(element, encoder);
    encoder.setType(Key.TYPE, element.type);
    encoder.setBool(Key.IS_FINAL, element.isFinal);
    encoder.setBool(Key.IS_CONST, element.isConst);
    if (element.isConst) {
      ConstantExpression constant = element.constant;
      encoder.setConstant(Key.CONSTANT, constant);
    }
    encoder.setElement(Key.EXECUTABLE_CONTEXT, element.executableContext);
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

  void serialize(ImportElement element, ObjectEncoder encoder,
      SerializedElementKind kind) {
    SerializerUtil.serializeMetadata(element, encoder);
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

  void serialize(ExportElement element, ObjectEncoder encoder,
      SerializedElementKind kind) {
    SerializerUtil.serializeMetadata(element, encoder);
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

  void serialize(PrefixElement element, ObjectEncoder encoder,
      SerializedElementKind kind) {
    encoder.setString(Key.NAME, element.name);
    encoder.setElement(Key.LIBRARY, element.library);
    encoder.setElement(Key.COMPILATION_UNIT, element.compilationUnit);
    encoder.setBool(Key.IS_DEFERRED, element.isDeferred);
    Set<Element> members = new Set<Element>();
    element.forEachLocalMember(SerializerUtil.flattenElements(members));
    encoder.setElements(Key.MEMBERS, members);
    if (element.isDeferred) {
      encoder.setElement(Key.IMPORT, element.deferredImport);
      encoder.setElement(Key.GETTER, element.loadLibrary);
    }
  }
}

class DeferredLoadLibrarySerializer implements ElementSerializer {
  const DeferredLoadLibrarySerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isDeferredLoaderGetter) {
      return SerializedElementKind.DEFERRED_LOAD_LIBRARY;
    }
    return null;
  }

  void serialize(GetterElement element, ObjectEncoder encoder,
      SerializedElementKind kind) {
    encoder.setElement(Key.PREFIX, element.enclosingElement);
  }
}

class WarnOnUseSerializer implements ElementSerializer {
  const WarnOnUseSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isWarnOnUse) {
      return SerializedElementKind.WARN_ON_USE;
    }
    return null;
  }

  void serialize(WarnOnUseElementX element, ObjectEncoder encoder,
      SerializedElementKind kind) {
    encoder.setElement(Key.ENCLOSING, element.enclosingElement);
    encoder.setElement(Key.ELEMENT, element.wrappedElement);
    serializeWrappedMessage(encoder, Key.WARNING, element.warning);
    serializeWrappedMessage(encoder, Key.INFO, element.info);
  }
}

class AmbiguousSerializer implements ElementSerializer {
  const AmbiguousSerializer();

  SerializedElementKind getSerializedKind(Element element) {
    if (element.isAmbiguous) {
      return SerializedElementKind.AMBIGUOUS;
    }
    return null;
  }

  void serialize(AmbiguousImportX element, ObjectEncoder encoder,
      SerializedElementKind kind) {
    // TODO(johnniwinther): Also support [DuplicateElementX] if serialization
    // of code with compile-time errors is supported.
    encoder.setElement(Key.ENCLOSING, element.enclosingElement);
    encoder.setElement(Key.EXISTING, element.existingElement);
    encoder.setElement(Key.NEW, element.newElement);
    encoder.setEnum(Key.MESSAGE_KIND, element.messageKind);
    serializeMessageArguments(encoder, Key.ARGUMENTS, element.messageArguments);
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
  /// [ResolutionDartType], and [ConstantExpression] that the deserialized
  /// [Element] depends upon are available.
  static Element deserialize(
      ObjectDecoder decoder, SerializedElementKind elementKind) {
    switch (elementKind) {
      case SerializedElementKind.ERROR:
        Element enclosing = decoder.getElement(Key.ENCLOSING);
        String name = decoder.getString(Key.NAME);
        MessageKind messageKind =
            decoder.getEnum(Key.MESSAGE_KIND, MessageKind.values);
        Map<String, String> arguments =
            deserializeMessageArguments(decoder, Key.ARGUMENTS);
        return new ErroneousElementX(messageKind, arguments, name, enclosing);
      case SerializedElementKind.LIBRARY:
        return new LibraryElementZ(decoder);
      case SerializedElementKind.COMPILATION_UNIT:
        return new CompilationUnitElementZ(decoder);
      case SerializedElementKind.CLASS:
        return new ClassElementZ(decoder);
      case SerializedElementKind.ENUM:
        return new EnumClassElementZ(decoder);
      case SerializedElementKind.NAMED_MIXIN_APPLICATION:
        return new NamedMixinApplicationElementZ(decoder);
      case SerializedElementKind.TOPLEVEL_FIELD:
        return new TopLevelFieldElementZ(decoder);
      case SerializedElementKind.STATIC_FIELD:
        return new StaticFieldElementZ(decoder);
      case SerializedElementKind.ENUM_CONSTANT:
        return new EnumConstantElementZ(decoder);
      case SerializedElementKind.INSTANCE_FIELD:
        return new InstanceFieldElementZ(decoder);
      case SerializedElementKind.GENERATIVE_CONSTRUCTOR:
        return new GenerativeConstructorElementZ(decoder);
      case SerializedElementKind.DEFAULT_CONSTRUCTOR:
        return new DefaultConstructorElementZ(decoder);
      case SerializedElementKind.FACTORY_CONSTRUCTOR:
        return new FactoryConstructorElementZ(decoder);
      case SerializedElementKind.REDIRECTING_FACTORY_CONSTRUCTOR:
        return new RedirectingFactoryConstructorElementZ(decoder);
      case SerializedElementKind.FORWARDING_CONSTRUCTOR:
        ClassElement cls = decoder.getElement(Key.CLASS);
        Element definingConstructor =
            deserializeElementReference(cls, Key.ELEMENT, Key.NAME, decoder);
        return new ForwardingConstructorElementZ(cls, definingConstructor);
      case SerializedElementKind.TOPLEVEL_FUNCTION:
        return new TopLevelFunctionElementZ(decoder);
      case SerializedElementKind.STATIC_FUNCTION:
        return new StaticFunctionElementZ(decoder);
      case SerializedElementKind.INSTANCE_FUNCTION:
        return new InstanceFunctionElementZ(decoder);
      case SerializedElementKind.LOCAL_FUNCTION:
        return new LocalFunctionElementZ(decoder);
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
        return new LocalParameterElementZ(decoder);
      case SerializedElementKind.INITIALIZING_FORMAL:
        return new InitializingFormalElementZ(decoder);
      case SerializedElementKind.IMPORT:
        return new ImportElementZ(decoder);
      case SerializedElementKind.EXPORT:
        return new ExportElementZ(decoder);
      case SerializedElementKind.PREFIX:
        return new PrefixElementZ(decoder);
      case SerializedElementKind.DEFERRED_LOAD_LIBRARY:
        return new DeferredLoaderGetterElementX(decoder.getElement(Key.PREFIX));
      case SerializedElementKind.LOCAL_VARIABLE:
        return new LocalVariableElementZ(decoder);
      case SerializedElementKind.WARN_ON_USE:
        Element enclosing = decoder.getElement(Key.ENCLOSING);
        Element element = decoder.getElement(Key.ELEMENT);
        WrappedMessage warning =
            deserializeWrappedMessage(decoder, Key.WARNING);
        WrappedMessage info = deserializeWrappedMessage(decoder, Key.INFO);
        return new WarnOnUseElementX(warning, info, enclosing, element);
      case SerializedElementKind.AMBIGUOUS:
        Element enclosingElement = decoder.getElement(Key.ENCLOSING);
        Element existingElement = decoder.getElement(Key.EXISTING);
        Element newElement = decoder.getElement(Key.NEW);
        MessageKind messageKind =
            decoder.getEnum(Key.MESSAGE_KIND, MessageKind.values);
        Map messageArguments =
            deserializeMessageArguments(decoder, Key.ARGUMENTS);
        return new AmbiguousImportX(messageKind, messageArguments,
            enclosingElement, existingElement, newElement);
      case SerializedElementKind.EXTERNAL_LIBRARY:
      case SerializedElementKind.EXTERNAL_LIBRARY_MEMBER:
      case SerializedElementKind.EXTERNAL_CLASS_MEMBER:
      case SerializedElementKind.EXTERNAL_CONSTRUCTOR:
        break;
    }
    throw new UnsupportedError("Unexpected element kind '${elementKind}.");
  }
}
