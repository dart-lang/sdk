// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Data structures representing an API definition, and visitor base classes
 * for visiting those data structures.
 */
import 'dart:collection';

import 'package:html/dom.dart' as dom;

/**
 * Toplevel container for the API.
 */
class Api extends ApiNode {
  final String version;
  final List<Domain> domains;
  final Types types;
  final Refactorings refactorings;

  Api(this.version, this.domains, this.types, this.refactorings,
      dom.Element html,
      {bool experimental})
      : super(html, experimental, false);
}

/**
 * Base class for objects in the API model.
 */
class ApiNode {
  /**
   * A flag to indicate if this API is experimental.
   */
  final bool experimental;

  /**
   * A flag to indicate if this API is deprecated.
   */
  final bool deprecated;

  /**
   * Html element representing this part of the API.
   */
  final dom.Element html;

  ApiNode(this.html, bool experimental, bool deprecated)
      : this.experimental = experimental ?? false,
        this.deprecated = deprecated ?? false;
}

/**
 * Base class for visiting the API definition.
 */
abstract class ApiVisitor<T> {
  /**
   * Dispatch the given [type] to the visitor.
   */
  T visitTypeDecl(TypeDecl type) => type.accept(this) as T;
  T visitTypeEnum(TypeEnum typeEnum);
  T visitTypeList(TypeList typeList);
  T visitTypeMap(TypeMap typeMap);
  T visitTypeObject(TypeObject typeObject);
  T visitTypeReference(TypeReference typeReference);

  T visitTypeUnion(TypeUnion typeUnion);
}

/**
 * Definition of a single domain.
 */
class Domain extends ApiNode {
  final String name;
  final List<Request> requests;
  final List<Notification> notifications;

  Domain(this.name, this.requests, this.notifications, dom.Element html,
      {bool experimental, bool deprecated})
      : super(html, experimental, deprecated);
}

/**
 * API visitor that visits the entire API hierarchically by default.
 */
class HierarchicalApiVisitor extends ApiVisitor {
  /**
   * The API to visit.
   */
  final Api api;

  HierarchicalApiVisitor(this.api);

  /**
   * If [type] is a [TypeReference] that is defined in the API, follow the
   * chain until a non-[TypeReference] is found, if possible.
   *
   * If it is not possible (because the chain ends with a [TypeReference] that
   * is not defined in the API), then that final [TypeReference] is returned.
   */
  TypeDecl resolveTypeReferenceChain(TypeDecl type) {
    while (type is TypeReference && api.types.containsKey(type.typeName)) {
      type = api.types[(type as TypeReference).typeName].type;
    }
    return type;
  }

  void visitApi() {
    api.domains.forEach(visitDomain);
    visitTypes(api.types);
    visitRefactorings(api.refactorings);
  }

  void visitDomain(Domain domain) {
    domain.requests.forEach(visitRequest);
    domain.notifications.forEach(visitNotification);
  }

  void visitNotification(Notification notification) {
    if (notification.params != null) {
      visitTypeDecl(notification.params);
    }
  }

  void visitRefactoring(Refactoring refactoring) {
    if (refactoring.feedback != null) {
      visitTypeDecl(refactoring.feedback);
    }
    if (refactoring.options != null) {
      visitTypeDecl(refactoring.options);
    }
  }

  void visitRefactorings(Refactorings refactorings) {
    refactorings?.forEach(visitRefactoring);
  }

  void visitRequest(Request request) {
    if (request.params != null) {
      visitTypeDecl(request.params);
    }
    if (request.result != null) {
      visitTypeDecl(request.result);
    }
  }

  void visitTypeDefinition(TypeDefinition typeDefinition) {
    visitTypeDecl(typeDefinition.type);
  }

  @override
  void visitTypeEnum(TypeEnum typeEnum) {
    typeEnum.values.forEach(visitTypeEnumValue);
  }

  void visitTypeEnumValue(TypeEnumValue typeEnumValue) {}

  @override
  void visitTypeList(TypeList typeList) {
    visitTypeDecl(typeList.itemType);
  }

  @override
  void visitTypeMap(TypeMap typeMap) {
    visitTypeDecl(typeMap.keyType);
    visitTypeDecl(typeMap.valueType);
  }

  @override
  void visitTypeObject(TypeObject typeObject) {
    typeObject.fields.forEach(visitTypeObjectField);
  }

  void visitTypeObjectField(TypeObjectField typeObjectField) {
    visitTypeDecl(typeObjectField.type);
  }

  @override
  void visitTypeReference(TypeReference typeReference) {}

  void visitTypes(Types types) {
    types.forEach(visitTypeDefinition);
  }

  @override
  void visitTypeUnion(TypeUnion typeUnion) {
    typeUnion.choices.forEach(visitTypeDecl);
  }
}

/**
 * Description of a notification method.
 */
class Notification extends ApiNode {
  /**
   * Name of the domain enclosing this request.
   */
  final String domainName;

  /**
   * Name of the notification, without the domain prefix.
   */
  final String event;

  /**
   * Type of the object associated with the "params" key in the notification
   * object, or null if the notification has no parameters.
   */
  final TypeObject params;

  Notification(this.domainName, this.event, this.params, dom.Element html,
      {bool experimental})
      : super(html, experimental, false);

  /**
   * Get the name of the notification, including the domain prefix.
   */
  String get longEvent => '$domainName.$event';

  /**
   * Get the full type of the notification object, including the common "id"
   * and "error" fields.
   */
  TypeDecl get notificationType {
    List<TypeObjectField> fields = [
      new TypeObjectField('event', new TypeReference('String', null), null,
          value: '$domainName.$event')
    ];
    if (params != null) {
      fields.add(new TypeObjectField('params', params, null));
    }
    return new TypeObject(fields, null);
  }
}

/**
 * Description of a single refactoring.
 */
class Refactoring extends ApiNode {
  /**
   * Name of the refactoring.  This should match one of the values allowed for
   * RefactoringKind.
   */
  final String kind;

  /**
   * Type of the refactoring feedback, or null if the refactoring has no
   * feedback.
   */
  final TypeObject feedback;

  /**
   * Type of the refactoring options, or null if the refactoring has no options.
   */
  final TypeObject options;

  Refactoring(this.kind, this.feedback, this.options, dom.Element html,
      {bool experimental})
      : super(html, experimental, false);
}

/**
 * A collection of refactoring definitions.
 */
class Refactorings extends ApiNode with IterableMixin<Refactoring> {
  final List<Refactoring> refactorings;

  Refactorings(this.refactorings, dom.Element html, {bool experimental})
      : super(html, experimental, false);

  @override
  Iterator<Refactoring> get iterator => refactorings.iterator;
}

/**
 * Description of a request method.
 */
class Request extends ApiNode {
  /**
   * Name of the domain enclosing this request.
   */
  final String domainName;

  /**
   * Name of the request, without the domain prefix.
   */
  final String method;

  /**
   * Type of the object associated with the "params" key in the request object,
   * or null if the request has no parameters.
   */
  final TypeObject params;

  /**
   * Type of the object associated with the "result" key in the response object,
   * or null if the response has no results.
   */
  final TypeObject result;

  Request(
      this.domainName, this.method, this.params, this.result, dom.Element html,
      {bool experimental, bool deprecated})
      : super(html, experimental, deprecated);

  /**
   * Get the name of the request, including the domain prefix.
   */
  String get longMethod => '$domainName.$method';

  /**
   * Get the full type of the request object, including the common "id" and
   * "method" fields.
   */
  TypeDecl get requestType {
    List<TypeObjectField> fields = [
      new TypeObjectField('id', new TypeReference('String', null), null),
      new TypeObjectField('method', new TypeReference('String', null), null,
          value: '$domainName.$method')
    ];
    if (params != null) {
      fields.add(new TypeObjectField('params', params, null));
    }
    return new TypeObject(fields, null);
  }

  /**
   * Get the full type of the response object, including the common "id" and
   * "error" fields.
   */
  TypeDecl get responseType {
    List<TypeObjectField> fields = [
      new TypeObjectField('id', new TypeReference('String', null), null),
      new TypeObjectField(
          'error', new TypeReference('RequestError', null), null,
          optional: true)
    ];
    if (result != null) {
      fields.add(new TypeObjectField('result', result, null));
    }
    return new TypeObject(fields, null);
  }
}

/**
 * Base class for all possible types.
 */
abstract class TypeDecl extends ApiNode {
  TypeDecl(dom.Element html, bool experimental, bool deprecated)
      : super(html, experimental, deprecated);

  accept(ApiVisitor visitor);
}

/**
 * Description of a named type definition.
 */
class TypeDefinition extends ApiNode {
  final String name;
  final TypeDecl type;

  bool isExternal = false;

  TypeDefinition(this.name, this.type, dom.Element html,
      {bool experimental, bool deprecated})
      : super(html, experimental, deprecated);
}

/**
 * Type of an enum.  We represent enums in JSON as strings, so this type
 * declaration simply lists the allowed values.
 */
class TypeEnum extends TypeDecl {
  final List<TypeEnumValue> values;

  TypeEnum(this.values, dom.Element html, {bool experimental, bool deprecated})
      : super(html, experimental, deprecated);

  @override
  accept(ApiVisitor visitor) => visitor.visitTypeEnum(this);
}

/**
 * Description of a single allowed value for an enum.
 */
class TypeEnumValue extends ApiNode {
  final String value;

  TypeEnumValue(this.value, dom.Element html,
      {bool experimental, bool deprecated})
      : super(html, experimental, deprecated);
}

/**
 * Type of a JSON list.
 */
class TypeList extends TypeDecl {
  final TypeDecl itemType;

  TypeList(this.itemType, dom.Element html, {bool experimental})
      : super(html, experimental, false);

  @override
  accept(ApiVisitor visitor) => visitor.visitTypeList(this);
}

/**
 * Type of a JSON map.
 */
class TypeMap extends TypeDecl {
  /**
   * Type of map keys.  Note that since JSON map keys must always be strings,
   * this must either be a [TypeReference] for [String], or a [TypeReference]
   * to a type which is defined in the API as an enum or a synonym for [String].
   */
  final TypeReference keyType;

  /**
   * Type of map values.
   */
  final TypeDecl valueType;

  TypeMap(this.keyType, this.valueType, dom.Element html, {bool experimental})
      : super(html, experimental, false);

  @override
  accept(ApiVisitor visitor) => visitor.visitTypeMap(this);
}

/**
 * Type of a JSON object with specified fields, some of which may be optional.
 */
class TypeObject extends TypeDecl {
  final List<TypeObjectField> fields;

  TypeObject(this.fields, dom.Element html,
      {bool experimental, bool deprecated})
      : super(html, experimental, deprecated);

  @override
  accept(ApiVisitor visitor) => visitor.visitTypeObject(this);

  /**
   * Return the field with the given [name], or null if there is no such field.
   */
  TypeObjectField getField(String name) {
    for (TypeObjectField field in fields) {
      if (field.name == name) {
        return field;
      }
    }
    return null;
  }
}

/**
 * Description of a single field in a [TypeObject].
 */
class TypeObjectField extends ApiNode {
  final String name;
  final TypeDecl type;
  final bool optional;

  /**
   * Value that the field is required to contain, or null if it may vary.
   */
  final Object value;

  TypeObjectField(this.name, this.type, dom.Element html,
      {this.optional: false, this.value, bool experimental, bool deprecated})
      : super(html, experimental, deprecated);
}

/**
 * A reference to a type which is either defined elsewhere in the API or which
 * is built-in ([String], [bool], or [int]).
 */
class TypeReference extends TypeDecl {
  final String typeName;

  TypeReference(this.typeName, dom.Element html, {bool experimental})
      : super(html, experimental, false) {
    if (typeName.isEmpty) {
      throw new Exception('Empty type name');
    }
  }

  @override
  accept(ApiVisitor visitor) => visitor.visitTypeReference(this);
}

/**
 * A collection of type definitions.
 */
class Types extends ApiNode with IterableMixin<TypeDefinition> {
  final Map<String, TypeDefinition> types;

  List<String> importUris = <String>[];

  Types(this.types, dom.Element html, {bool experimental})
      : super(html, experimental, false);

  @override
  Iterator<TypeDefinition> get iterator => types.values.iterator;

  Iterable<String> get keys => types.keys;

  TypeDefinition operator [](String typeName) => types[typeName];

  bool containsKey(String typeName) => types.containsKey(typeName);
}

/**
 * Type which represents a union among multiple choices.
 */
class TypeUnion extends TypeDecl {
  final List<TypeDecl> choices;

  /**
   * The field that is used to disambiguate this union
   */
  final String field;

  TypeUnion(this.choices, this.field, dom.Element html, {bool experimental})
      : super(html, experimental, false);

  @override
  accept(ApiVisitor visitor) => visitor.visitTypeUnion(this);
}
