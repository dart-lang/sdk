// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Code for reading an HTML API description.
 */
import 'dart:io';

import 'package:analyzer/src/codegen/html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:path/path.dart';

import 'api.dart';

/**
 * Read the API description from the file 'plugin_spec.html'.  [pkgPath] is the
 * path to the current package.
 */
Api readApi(String pkgPath) {
  ApiReader reader =
      new ApiReader(join(pkgPath, 'tool', 'spec', 'plugin_spec.html'));
  return reader.readApi();
}

typedef void ElementProcessor(dom.Element element);

typedef void TextProcessor(dom.Text text);

class ApiReader {
  static const List<String> specialElements = const [
    'domain',
    'feedback',
    'object',
    'refactorings',
    'refactoring',
    'type',
    'types',
    'request',
    'notification',
    'params',
    'result',
    'field',
    'list',
    'map',
    'enum',
    'key',
    'value',
    'options',
    'ref',
    'code',
    'version',
    'union',
    'index',
    'include'
  ];

  /**
   * The absolute and normalized path to the file being read.
   */
  final String filePath;

  /**
   * Initialize a newly created API reader to read from the file with the given
   * [filePath].
   */
  ApiReader(this.filePath);

  /**
   * Create an [Api] object from an HTML representation such as:
   *
   * <html>
   *   ...
   *   <body>
   *     ... <version>1.0</version> ...
   *     <domain name="...">...</domain> <!-- zero or more -->
   *     <types>...</types>
   *     <refactorings>...</refactorings>
   *   </body>
   * </html>
   *
   * Child elements of <api> can occur in any order.
   */
  Api apiFromHtml(dom.Element html) {
    Api api;
    List<String> versions = <String>[];
    List<Domain> domains = <Domain>[];
    Types types = null;
    Refactorings refactorings = null;
    recurse(html, 'api', {
      'domain': (dom.Element element) {
        domains.add(domainFromHtml(element));
      },
      'refactorings': (dom.Element element) {
        refactorings = refactoringsFromHtml(element);
      },
      'types': (dom.Element element) {
        types = typesFromHtml(element);
      },
      'version': (dom.Element element) {
        versions.add(innerText(element));
      },
      'index': (dom.Element element) {
        /* Ignore; generated dynamically. */
      }
    });
    if (versions.length != 1) {
      throw new Exception('The API must contain exactly one <version> element');
    }
    api = new Api(versions[0], domains, types, refactorings, html);
    return api;
  }

  /**
   * Check that the given [element] has all of the attributes in
   * [requiredAttributes], possibly some of the attributes in
   * [optionalAttributes], and no others.
   */
  void checkAttributes(
      dom.Element element, List<String> requiredAttributes, String context,
      {List<String> optionalAttributes: const []}) {
    Set<String> attributesFound = new Set<String>();
    element.attributes.forEach((String name, String value) {
      if (!requiredAttributes.contains(name) &&
          !optionalAttributes.contains(name)) {
        throw new Exception(
            '$context: Unexpected attribute in ${element.localName}: $name');
      }
      attributesFound.add(name);
    });
    for (String expectedAttribute in requiredAttributes) {
      if (!attributesFound.contains(expectedAttribute)) {
        throw new Exception(
            '$context: ${element.localName} must contain attribute $expectedAttribute');
      }
    }
  }

  /**
   * Check that the given [element] has the given [expectedName].
   */
  void checkName(dom.Element element, String expectedName, [String context]) {
    if (element.localName != expectedName) {
      if (context == null) {
        context = element.localName;
      }
      throw new Exception(
          '$context: Expected $expectedName, found ${element.localName}');
    }
  }

  /**
   * Create a [Domain] object from an HTML representation such as:
   *
   * <domain name="domainName">
   *   <request method="...">...</request> <!-- zero or more -->
   *   <notification event="...">...</notification> <!-- zero or more -->
   * </domain>
   *
   * Child elements can occur in any order.
   */
  Domain domainFromHtml(dom.Element html) {
    checkName(html, 'domain');
    String name = html.attributes['name'];
    String context = name ?? 'domain';
    bool experimental = html.attributes['experimental'] == 'true';
    checkAttributes(html, ['name'], context,
        optionalAttributes: ['experimental']);
    List<Request> requests = <Request>[];
    List<Notification> notifications = <Notification>[];
    recurse(html, context, {
      'request': (dom.Element child) {
        requests.add(requestFromHtml(child, context));
      },
      'notification': (dom.Element child) {
        notifications.add(notificationFromHtml(child, context));
      }
    });
    return new Domain(name, requests, notifications, html,
        experimental: experimental);
  }

  dom.Element getAncestor(dom.Element html, String name, String context) {
    dom.Element ancestor = html.parent;
    while (ancestor != null) {
      if (ancestor.localName == name) {
        return ancestor;
      }
      ancestor = ancestor.parent;
    }
    throw new Exception(
        '$context: <${html.localName}> must be nested within <$name>');
  }

  /**
   * Create a [Notification] object from an HTML representation such as:
   *
   * <notification event="methodName">
   *   <params>...</params> <!-- optional -->
   * </notification>
   *
   * Note that the event name should not include the domain name.
   *
   * <params> has the same form as <object>, as described in [typeDeclFromHtml].
   *
   * Child elements can occur in any order.
   */
  Notification notificationFromHtml(dom.Element html, String context) {
    String domainName = getAncestor(html, 'domain', context).attributes['name'];
    checkName(html, 'notification', context);
    String event = html.attributes['event'];
    context = '$context.${event != null ? event : 'event'}';
    checkAttributes(html, ['event'], context);
    TypeDecl params;
    recurse(html, context, {
      'params': (dom.Element child) {
        params = typeObjectFromHtml(child, '$context.params');
      }
    });
    return new Notification(domainName, event, params, html);
  }

  /**
   * Create a single of [TypeDecl] corresponding to the type defined inside the
   * given HTML element.
   */
  TypeDecl processContentsAsType(dom.Element html, String context) {
    List<TypeDecl> types = processContentsAsTypes(html, context);
    if (types.length != 1) {
      throw new Exception('$context: Exactly one type must be specified');
    }
    return types[0];
  }

  /**
   * Create a list of [TypeDecl]s corresponding to the types defined inside the
   * given HTML element.  The following forms are supported.
   *
   * To refer to a type declared elsewhere (or a built-in type):
   *
   *   <ref>typeName</ref>
   *
   * For a list: <list>ItemType</list>
   *
   * For a map: <map><key>KeyType</key><value>ValueType</value></map>
   *
   * For a JSON object:
   *
   *   <object>
   *     <field name="...">...</field> <!-- zero or more -->
   *   </object>
   *
   * For an enum:
   *
   *   <enum>
   *     <value>...</value> <!-- zero or more -->
   *   </enum>
   *
   * For a union type:
   *   <union>
   *     TYPE <!-- zero or more -->
   *   </union>
   */
  List<TypeDecl> processContentsAsTypes(dom.Element html, String context) {
    List<TypeDecl> types = <TypeDecl>[];
    recurse(html, context, {
      'object': (dom.Element child) {
        types.add(typeObjectFromHtml(child, context));
      },
      'list': (dom.Element child) {
        checkAttributes(child, [], context);
        types.add(new TypeList(processContentsAsType(child, context), child));
      },
      'map': (dom.Element child) {
        checkAttributes(child, [], context);
        TypeDecl keyType;
        TypeDecl valueType;
        recurse(child, context, {
          'key': (dom.Element child) {
            if (keyType != null) {
              throw new Exception('$context: Key type already specified');
            }
            keyType = processContentsAsType(child, '$context.key');
          },
          'value': (dom.Element child) {
            if (valueType != null) {
              throw new Exception('$context: Value type already specified');
            }
            valueType = processContentsAsType(child, '$context.value');
          }
        });
        if (keyType == null) {
          throw new Exception('$context: Key type not specified');
        }
        if (valueType == null) {
          throw new Exception('$context: Value type not specified');
        }
        types.add(new TypeMap(keyType, valueType, child));
      },
      'enum': (dom.Element child) {
        types.add(typeEnumFromHtml(child, context));
      },
      'ref': (dom.Element child) {
        checkAttributes(child, [], context);
        types.add(new TypeReference(innerText(child), child));
      },
      'union': (dom.Element child) {
        checkAttributes(child, ['field'], context);
        String field = child.attributes['field'];
        types.add(new TypeUnion(
            processContentsAsTypes(child, context), field, child));
      }
    });
    return types;
  }

  /**
   * Read the API description from file with the given [filePath].
   */
  Api readApi() {
    String htmlContents = new File(filePath).readAsStringSync();
    dom.Document document = parser.parse(htmlContents);
    dom.Element htmlElement = document.children
        .singleWhere((element) => element.localName.toLowerCase() == 'html');
    return apiFromHtml(htmlElement);
  }

  void recurse(dom.Element parent, String context,
      Map<String, ElementProcessor> elementProcessors) {
    for (String key in elementProcessors.keys) {
      if (!specialElements.contains(key)) {
        throw new Exception('$context: $key is not a special element');
      }
    }
    for (dom.Node node in parent.nodes) {
      if (node is dom.Element) {
        if (elementProcessors.containsKey(node.localName)) {
          elementProcessors[node.localName](node);
        } else if (specialElements.contains(node.localName)) {
          throw new Exception(
              '$context: Unexpected use of <${node.localName}>');
        } else {
          recurse(node, context, elementProcessors);
        }
      }
    }
  }

  /**
   * Create a [Refactoring] object from an HTML representation such as:
   *
   * <refactoring kind="refactoringKind">
   *   <feedback>...</feedback> <!-- optional -->
   *   <options>...</options> <!-- optional -->
   * </refactoring>
   *
   * <feedback> and <options> have the same form as <object>, as described in
   * [typeDeclFromHtml].
   *
   * Child elements can occur in any order.
   */
  Refactoring refactoringFromHtml(dom.Element html) {
    checkName(html, 'refactoring');
    String kind = html.attributes['kind'];
    String context = kind != null ? kind : 'refactoring';
    checkAttributes(html, ['kind'], context);
    TypeDecl feedback;
    TypeDecl options;
    recurse(html, context, {
      'feedback': (dom.Element child) {
        feedback = typeObjectFromHtml(child, '$context.feedback');
      },
      'options': (dom.Element child) {
        options = typeObjectFromHtml(child, '$context.options');
      }
    });
    return new Refactoring(kind, feedback, options, html);
  }

  /**
   * Create a [Refactorings] object from an HTML representation such as:
   *
   * <refactorings>
   *   <refactoring kind="...">...</refactoring> <!-- zero or more -->
   * </refactorings>
   */
  Refactorings refactoringsFromHtml(dom.Element html) {
    checkName(html, 'refactorings');
    String context = 'refactorings';
    checkAttributes(html, [], context);
    List<Refactoring> refactorings = <Refactoring>[];
    recurse(html, context, {
      'refactoring': (dom.Element child) {
        refactorings.add(refactoringFromHtml(child));
      }
    });
    return new Refactorings(refactorings, html);
  }

  /**
   * Create a [Request] object from an HTML representation such as:
   *
   * <request method="methodName">
   *   <params>...</params> <!-- optional -->
   *   <result>...</result> <!-- optional -->
   * </request>
   *
   * Note that the method name should not include the domain name.
   *
   * <params> and <result> have the same form as <object>, as described in
   * [typeDeclFromHtml].
   *
   * Child elements can occur in any order.
   */
  Request requestFromHtml(dom.Element html, String context) {
    String domainName = getAncestor(html, 'domain', context).attributes['name'];
    checkName(html, 'request', context);
    String method = html.attributes['method'];
    context = '$context.${method != null ? method : 'method'}';
    checkAttributes(html, ['method'], context,
        optionalAttributes: ['experimental', 'deprecated']);
    bool experimental = html.attributes['experimental'] == 'true';
    bool deprecated = html.attributes['deprecated'] == 'true';
    TypeDecl params;
    TypeDecl result;
    recurse(html, context, {
      'params': (dom.Element child) {
        params = typeObjectFromHtml(child, '$context.params');
      },
      'result': (dom.Element child) {
        result = typeObjectFromHtml(child, '$context.result');
      }
    });
    return new Request(domainName, method, params, result, html,
        experimental: experimental, deprecated: deprecated);
  }

  /**
   * Create a [TypeDefinition] object from an HTML representation such as:
   *
   * <type name="typeName">
   *   TYPE
   * </type>
   *
   * Where TYPE is any HTML that can be parsed by [typeDeclFromHtml].
   *
   * Child elements can occur in any order.
   */
  TypeDefinition typeDefinitionFromHtml(dom.Element html) {
    checkName(html, 'type');
    String name = html.attributes['name'];
    String context = name != null ? name : 'type';
    checkAttributes(html, ['name'], context,
        optionalAttributes: ['experimental', 'deprecated']);
    TypeDecl type = processContentsAsType(html, context);
    bool experimental = html.attributes['experimental'] == 'true';
    bool deprecated = html.attributes['deprecated'] == 'true';
    return new TypeDefinition(name, type, html,
        experimental: experimental, deprecated: deprecated);
  }

  /**
   * Create a [TypeEnum] from an HTML description.
   */
  TypeEnum typeEnumFromHtml(dom.Element html, String context) {
    checkName(html, 'enum', context);
    checkAttributes(html, [], context);
    List<TypeEnumValue> values = <TypeEnumValue>[];
    recurse(html, context, {
      'value': (dom.Element child) {
        values.add(typeEnumValueFromHtml(child, context));
      }
    });
    return new TypeEnum(values, html);
  }

  /**
   * Create a [TypeEnumValue] from an HTML description such as:
   *
   * <enum>
   *   <code>VALUE</code>
   * </enum>
   *
   * Where VALUE is the text of the enumerated value.
   *
   * Child elements can occur in any order.
   */
  TypeEnumValue typeEnumValueFromHtml(dom.Element html, String context) {
    checkName(html, 'value', context);
    checkAttributes(html, [], context, optionalAttributes: ['deprecated']);
    bool deprecated = html.attributes['deprecated'] == 'true';
    List<String> values = <String>[];
    recurse(html, context, {
      'code': (dom.Element child) {
        String text = innerText(child).trim();
        values.add(text);
      }
    });
    if (values.length != 1) {
      throw new Exception('$context: Exactly one value must be specified');
    }
    return new TypeEnumValue(values[0], html, deprecated: deprecated);
  }

  /**
   * Create a [TypeObjectField] from an HTML description such as:
   *
   * <field name="fieldName">
   *   TYPE
   * </field>
   *
   * Where TYPE is any HTML that can be parsed by [typeDeclFromHtml].
   *
   * In addition, the attribute optional="true" may be used to specify that the
   * field is optional, and the attribute value="..." may be used to specify that
   * the field is required to have a certain value.
   *
   * Child elements can occur in any order.
   */
  TypeObjectField typeObjectFieldFromHtml(dom.Element html, String context) {
    checkName(html, 'field', context);
    String name = html.attributes['name'];
    context = '$context.${name != null ? name : 'field'}';
    checkAttributes(html, ['name'], context,
        optionalAttributes: ['optional', 'value', 'deprecated']);
    bool deprecated = html.attributes['deprecated'] == 'true';
    bool optional = false;
    String optionalString = html.attributes['optional'];
    if (optionalString != null) {
      switch (optionalString) {
        case 'true':
          optional = true;
          break;
        case 'false':
          optional = false;
          break;
        default:
          throw new Exception(
              '$context: field contains invalid "optional" attribute: "$optionalString"');
      }
    }
    String value = html.attributes['value'];
    TypeDecl type = processContentsAsType(html, context);
    return new TypeObjectField(name, type, html,
        optional: optional, value: value, deprecated: deprecated);
  }

  /**
   * Create a [TypeObject] from an HTML description.
   */
  TypeObject typeObjectFromHtml(dom.Element html, String context) {
    checkAttributes(html, [], context, optionalAttributes: ['experimental']);
    List<TypeObjectField> fields = <TypeObjectField>[];
    recurse(html, context, {
      'field': (dom.Element child) {
        fields.add(typeObjectFieldFromHtml(child, context));
      }
    });
    bool experimental = html.attributes['experimental'] == 'true';
    return new TypeObject(fields, html, experimental: experimental);
  }

  /**
   * Create a [Types] object from an HTML representation such as:
   *
   * <types>
   *   <type name="...">...</type> <!-- zero or more -->
   * </types>
   */
  Types typesFromHtml(dom.Element html) {
    checkName(html, 'types');
    String context = 'types';
    checkAttributes(html, [], context);
    List<String> importUris = <String>[];
    Map<String, TypeDefinition> typeMap = <String, TypeDefinition>{};
    List<dom.Element> childElements = <dom.Element>[];
    recurse(html, context, {
      'include': (dom.Element child) {
        String importUri = child.attributes['import'];
        if (importUri != null) {
          importUris.add(importUri);
        }
        String relativePath = child.attributes['path'];
        String path = normalize(join(dirname(filePath), relativePath));
        ApiReader reader = new ApiReader(path);
        Api api = reader.readApi();
        for (TypeDefinition typeDefinition in api.types) {
          typeDefinition.isExternal = true;
          childElements.add(typeDefinition.html);
          typeMap[typeDefinition.name] = typeDefinition;
        }
      },
      'type': (dom.Element child) {
        TypeDefinition typeDefinition = typeDefinitionFromHtml(child);
        typeMap[typeDefinition.name] = typeDefinition;
      }
    });
    for (dom.Element element in childElements) {
      html.append(element);
    }
    Types types = new Types(typeMap, html);
    types.importUris.addAll(importUris);
    return types;
  }
}
