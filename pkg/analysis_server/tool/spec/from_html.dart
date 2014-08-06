// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Code for reading an HTML API description.
 */
library from.html;

import 'dart:io';

import 'package:html5lib/dom.dart' as dom;
import 'package:html5lib/parser.dart' as parser;

import 'api.dart';
import 'html_tools.dart';

/**
 * Check that the given [element] has the given [expectedName].
 */
void checkName(dom.Element element, String expectedName) {
  if (element.localName != expectedName) {
    throw new Exception('Expected $expectedName, found ${element.localName}');
  }
}

/**
 * Check that the given [element] has all of the attributes in
 * [requiredAttributes], possibly some of the attributes in
 * [optionalAttributes], and no others.
 */
void checkAttributes(dom.Element element, List<String>
    requiredAttributes, {List<String> optionalAttributes: const []}) {
  Set<String> attributesFound = new Set<String>();
  element.attributes.forEach((String name, String value) {
    if (!requiredAttributes.contains(name) && !optionalAttributes.contains(name
        )) {
      throw new Exception('Unexpected attribute in ${element.localName}: $name'
          );
    }
    attributesFound.add(name);
  });
  for (String expectedAttribute in requiredAttributes) {
    if (!attributesFound.contains(expectedAttribute)) {
      throw new Exception(
          '${element.localName} must contain attribute ${expectedAttribute}');
    }
  }
}

const List<String> specialElements = const ['domain', 'feedback',
    'object', 'refactorings', 'refactoring', 'type', 'types', 'request',
    'notification', 'params', 'result', 'field', 'list', 'map', 'enum', 'key',
    'value', 'options', 'ref', 'code', 'version'];

typedef void ElementProcessor(dom.Element element);
typedef void TextProcessor(dom.Text text);

void recurse(dom.Element parent, Map<String, ElementProcessor>
    elementProcessors) {
  for (String key in elementProcessors.keys) {
    if (!specialElements.contains(key)) {
      throw new Exception('$key is not a special element');
    }
  }
  for (dom.Node node in parent.nodes) {
    if (node is dom.Element) {
      if (elementProcessors.containsKey(node.localName)) {
        elementProcessors[node.localName](node);
      } else if (specialElements.contains(node.localName)) {
        throw new Exception('Unexpected use of <${node.localName}');
      } else {
        recurse(node, elementProcessors);
      }
    }
  }
}

dom.Element getAncestor(dom.Element html, String name) {
  dom.Element ancestor = html.parent;
  while (ancestor != null) {
    if (ancestor.localName == name) {
      return ancestor;
    }
    ancestor = ancestor.parent;
  }
  throw new Exception('<${html.localName}> must be nested within <$name>');
}

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
  recurse(html, {
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
    }
  });
  if (versions.length != 1) {
    throw new Exception('The API must contain exactly one <version> element');
  }
  api = new Api(versions[0], domains, types, refactorings, html);
  return api;
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
  checkAttributes(html, []);
  List<Refactoring> refactorings = <Refactoring>[];
  recurse(html, {
    'refactoring': (dom.Element child) {
      refactorings.add(refactoringFromHtml(child));
    }
  });
  return new Refactorings(refactorings, html);
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
  checkAttributes(html, ['kind']);
  String kind = html.attributes['kind'];
  TypeDecl feedback;
  TypeDecl options;
  recurse(html, {
    'feedback': (dom.Element child) {
      feedback = typeObjectFromHtml(child);
    },
    'options': (dom.Element child) {
      options = typeObjectFromHtml(child);
    }
  });
  return new Refactoring(kind, feedback, options, html);
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
  checkAttributes(html, []);
  Map<String, TypeDefinition> types = <String, TypeDefinition> {};
  recurse(html, {
    'type': (dom.Element child) {
      TypeDefinition typeDefinition = typeDefinitionFromHtml(child);
      types[typeDefinition.name] = typeDefinition;
    }
  });
  return new Types(types, html);
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
  checkAttributes(html, ['name']);
  String name = html.attributes['name'];
  TypeDecl type = processContentsAsType(html);
  return new TypeDefinition(name, type, html);
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
  checkAttributes(html, ['name']);
  String name = html.attributes['name'];
  List<Request> requests = <Request>[];
  List<Notification> notifications = <Notification>[];
  recurse(html, {
    'request': (dom.Element child) {
      requests.add(requestFromHtml(child));
    },
    'notification': (dom.Element child) {
      notifications.add(notificationFromHtml(child));
    }
  });
  return new Domain(name, requests, notifications, html);
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
Request requestFromHtml(dom.Element html) {
  String domainName = getAncestor(html, 'domain').attributes['name'];
  checkName(html, 'request');
  checkAttributes(html, ['method']);
  String method = html.attributes['method'];
  TypeDecl params;
  TypeDecl result;
  recurse(html, {
    'params': (dom.Element child) {
      params = typeObjectFromHtml(child);
    },
    'result': (dom.Element child) {
      result = typeObjectFromHtml(child);
    }
  });
  return new Request(domainName, method, params, result, html);
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
Notification notificationFromHtml(dom.Element html) {
  String domainName = getAncestor(html, 'domain').attributes['name'];
  checkName(html, 'notification');
  checkAttributes(html, ['event']);
  String event = html.attributes['event'];
  TypeDecl params;
  recurse(html, {
    'params': (dom.Element child) {
      params = typeObjectFromHtml(child);
    }
  });
  return new Notification(domainName, event, params, html);
}

/**
 * Create a [TypeDecl] from an HTML description.  The following forms are
 * supported.
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
 */
TypeDecl processContentsAsType(dom.Element html) {
  List<TypeDecl> types = <TypeDecl>[];
  recurse(html, {
    'object': (dom.Element child) {
      types.add(typeObjectFromHtml(child));
    },
    'list': (dom.Element child) {
      checkAttributes(child, []);
      types.add(new TypeList(processContentsAsType(child), child));
    },
    'map': (dom.Element child) {
      checkAttributes(child, []);
      TypeDecl keyType;
      TypeDecl valueType;
      recurse(child, {
        'key': (dom.Element child) {
          if (keyType != null) {
            throw new Exception('Key type already specified');
          }
          keyType = processContentsAsType(child);
        },
        'value': (dom.Element child) {
          if (valueType != null) {
            throw new Exception('Value type already specified');
          }
          valueType = processContentsAsType(child);
        }
      });
      if (keyType == null) {
        throw new Exception('Key type not specified');
      }
      if (valueType == null) {
        throw new Exception('Value type not specified');
      }
      types.add(new TypeMap(keyType, valueType, child));
    },
    'enum': (dom.Element child) {
      types.add(typeEnumFromHtml(child));
    },
    'ref': (dom.Element child) {
      checkAttributes(child, []);
      types.add(new TypeReference(innerText(child), child));
    }
  });
  if (types.length != 1) {
    throw new Exception('Exactly one type must be specified');
  }
  return types[0];
}

/**
 * Create a [TypeEnum] from an HTML description.
 */
TypeEnum typeEnumFromHtml(dom.Element html) {
  checkName(html, 'enum');
  checkAttributes(html, []);
  List<TypeEnumValue> values = <TypeEnumValue>[];
  recurse(html, {
    'value': (dom.Element child) {
      values.add(typeEnumValueFromHtml(child));
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
TypeEnumValue typeEnumValueFromHtml(dom.Element html) {
  checkName(html, 'value');
  checkAttributes(html, []);
  List<String> values = <String>[];
  recurse(html, {
    'code': (dom.Element child) {
      String text = innerText(child).trim();
      values.add(text);
    }
  });
  if (values.length != 1) {
    throw new Exception('Exactly one value must be specified');
  }
  return new TypeEnumValue(values[0], html);
}

/**
 * Create a [TypeObject] from an HTML description.
 */
TypeObject typeObjectFromHtml(dom.Element html) {
  checkAttributes(html, []);
  List<TypeObjectField> fields = <TypeObjectField>[];
  recurse(html, {
    'field': (dom.Element child) {
      fields.add(typeObjectFieldFromHtml(child));
    }
  });
  return new TypeObject(fields, html);
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
TypeObjectField typeObjectFieldFromHtml(dom.Element html) {
  checkName(html, 'field');
  checkAttributes(html, ['name'], optionalAttributes: ['optional', 'value']);
  String name = html.attributes['name'];
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
            'field contains invalid "optional" attribute: "$optionalString"');
    }
  }
  String value = html.attributes['value'];
  TypeDecl type = processContentsAsType(html);
  return new TypeObjectField(name, type, html, optional: optional, value: value
      );
}

/**
 * Read the API description from the file 'spec_input.html'.
 */
Api readApi() {
  File htmlFile = new File('spec_input.html');
  String htmlContents = htmlFile.readAsStringSync();
  dom.Document document = parser.parse(htmlContents);
  return apiFromHtml(document.firstChild);
}
