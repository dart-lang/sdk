// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Code for displaying the API as HTML.  This is used both for generating a
 * full description of the API as a web page, and for generating doc comments
 * in generated code.
 */
import 'dart:convert';

import 'package:analyzer/src/codegen/html.dart';
import 'package:analyzer/src/codegen/tools.dart';
import 'package:front_end/src/codegen/tools.dart';
import 'package:html/dom.dart' as dom;

import 'api.dart';
import 'from_html.dart';

/**
 * Embedded stylesheet
 */
final String stylesheet = '''
body {
  font-family: 'Roboto', sans-serif;
  max-width: 800px;
  margin: 0 auto;
  padding: 0 16px;
  font-size: 16px;
  line-height: 1.5;
  color: #111;
  background-color: #fdfdfd;
  font-weight: 300;
  -webkit-font-smoothing: auto;
}

h2, h3, h4, h5 {
  margin-bottom: 0;
}

h2.domain {
  border-bottom: 1px solid rgb(200, 200, 200);
  margin-bottom: 0.5em;
}

h4 {
  font-size: 18px;
}

h5 {
  font-size: 16px;
}

p {
  margin-top: 0;
}

pre {
  margin: 0;
  font-family: 'Source Code Pro', monospace;
  font-size: 15px;
}

div.box {
  background-color: rgb(240, 245, 240);
  border-radius: 4px;
  padding: 4px 12px;
  margin: 16px 0;
}

div.hangingIndent {
  padding-left: 3em;
  text-indent: -3em;
}

dl dt {
  font-weight: bold;
}

dl dd {
  margin-left: 16px;
}

dt {
  margin-top: 1em;
}

dt.notification {
  font-weight: bold;
}

dt.refactoring {
  font-weight: bold;
}

dt.request {
  font-weight: bold;
}

dt.typeDefinition {
  font-weight: bold;
}

a {
  text-decoration: none;
}

a:focus, a:hover {
  text-decoration: underline;
}

.deprecated {
  text-decoration: line-through;
}

/* Styles for index */

.subindex ul {
  padding-left: 0;
  margin-left: 0;

  -webkit-margin-before: 0;
  -webkit-margin-start: 0;
  -webkit-padding-start: 0;

  list-style-type: none;
}
'''
    .trim();

final GeneratedFile target =
    new GeneratedFile('doc/api.html', (String pkgPath) {
  ToHtmlVisitor visitor = new ToHtmlVisitor(readApi(pkgPath));
  dom.Document document = new dom.Document();
  document.append(new dom.DocumentType('html', null, null));
  for (dom.Node node in visitor.collectHtml(visitor.visitApi)) {
    document.append(node);
  }
  return document.outerHtml;
});

String _toTitleCase(String str) {
  if (str.isEmpty) return str;
  return str.substring(0, 1).toUpperCase() + str.substring(1);
}

/**
 * Visitor that records the mapping from HTML elements to various kinds of API
 * nodes.
 */
class ApiMappings extends HierarchicalApiVisitor {
  Map<dom.Element, Domain> domains = <dom.Element, Domain>{};

  ApiMappings(Api api) : super(api);

  @override
  void visitDomain(Domain domain) {
    domains[domain.html] = domain;
  }
}

/**
 * Helper methods for creating HTML elements.
 */
abstract class HtmlMixin {
  void anchor(String id, void callback()) {
    element('a', {'name': id}, callback);
  }

  void b(void callback()) => element('b', {}, callback);
  void body(void callback()) => element('body', {}, callback);
  void box(void callback()) {
    element('div', {'class': 'box'}, callback);
  }

  void br() => element('br', {});
  void dd(void callback()) => element('dd', {}, callback);
  void dl(void callback()) => element('dl', {}, callback);
  void dt(String cls, void callback()) =>
      element('dt', {'class': cls}, callback);
  void element(String name, Map<dynamic, String> attributes, [void callback()]);
  void gray(void callback()) =>
      element('span', {'style': 'color:#999999'}, callback);
  void h1(void callback()) => element('h1', {}, callback);
  void h2(String cls, void callback()) {
    if (cls == null) {
      return element('h2', {}, callback);
    }
    return element('h2', {'class': cls}, callback);
  }

  void h3(void callback()) => element('h3', {}, callback);
  void h4(void callback()) => element('h4', {}, callback);
  void h5(void callback()) => element('h5', {}, callback);
  void hangingIndent(void callback()) =>
      element('div', {'class': 'hangingIndent'}, callback);
  void head(void callback()) => element('head', {}, callback);
  void html(void callback()) => element('html', {}, callback);
  void i(void callback()) => element('i', {}, callback);
  void li(void callback()) => element('li', {}, callback);
  void link(String id, void callback(), [Map<dynamic, String> attributes]) {
    attributes ??= {};
    attributes['href'] = '#$id';
    element('a', attributes, callback);
  }

  void p(void callback()) => element('p', {}, callback);
  void pre(void callback()) => element('pre', {}, callback);
  void span(String cls, void callback()) =>
      element('span', {'class': cls}, callback);
  void title(void callback()) => element('title', {}, callback);
  void tt(void callback()) => element('tt', {}, callback);
  void ul(void callback()) => element('ul', {}, callback);
}

/**
 * Visitor that generates HTML documentation of the API.
 */
class ToHtmlVisitor extends HierarchicalApiVisitor
    with HtmlMixin, HtmlGenerator {
  /**
   * Set of types defined in the API.
   */
  Set<String> definedTypes = new Set<String>();

  /**
   * Mappings from HTML elements to API nodes.
   */
  ApiMappings apiMappings;

  ToHtmlVisitor(Api api)
      : apiMappings = new ApiMappings(api),
        super(api) {
    apiMappings.visitApi();
  }

  /**
   * Describe the payload of request, response, notification, refactoring
   * feedback, or refactoring options.
   *
   * If [force] is true, then a section is inserted even if the payload is
   * null.
   */
  void describePayload(TypeObject subType, String name, {bool force: false}) {
    if (force || subType != null) {
      h4(() {
        write(name);
      });
      if (subType == null) {
        p(() {
          write('none');
        });
      } else {
        visitTypeDecl(subType);
      }
    }
  }

  void generateDomainIndex(Domain domain) {
    h4(() {
      write(domain.name);
      write(' (');
      link('domain_${domain.name}', () => write('\u2191'));
      write(')');
    });
    if (domain.requests.length > 0) {
      element('div', {'class': 'subindex'}, () {
        generateRequestsIndex(domain.requests);
        if (domain.notifications.length > 0) {
          generateNotificationsIndex(domain.notifications);
        }
      });
    } else if (domain.notifications.length > 0) {
      element('div', {'class': 'subindex'}, () {
        generateNotificationsIndex(domain.notifications);
      });
    }
  }

  void generateDomainsHeader() {
    h1(() {
      write('Domains');
    });
  }

  void generateIndex() {
    h3(() => write('Domains'));
    for (var domain in api.domains) {
      if (domain.experimental ||
          (domain.requests.length == 0 && domain.notifications == 0)) {
        continue;
      }
      generateDomainIndex(domain);
    }

    generateTypesIndex(definedTypes);
    generateRefactoringsIndex(api.refactorings);
  }

  void generateNotificationsIndex(Iterable<Notification> notifications) {
    h5(() => write("Notifications"));
    element('div', {'class': 'subindex'}, () {
      element('ul', {}, () {
        for (var notification in notifications) {
          element(
              'li',
              {},
              () => link('notification_${notification.longEvent}',
                  () => write(notification.event)));
        }
      });
    });
  }

  void generateRefactoringsIndex(Iterable<Refactoring> refactorings) {
    if (refactorings == null) {
      return;
    }
    h3(() {
      write("Refactorings");
      write(' (');
      link('refactorings', () => write('\u2191'));
      write(')');
    });
    // TODO: Individual refactorings are not yet hyperlinked.
    element('div', {'class': 'subindex'}, () {
      element('ul', {}, () {
        for (var refactoring in refactorings) {
          element(
              'li',
              {},
              () => link('refactoring_${refactoring.kind}',
                  () => write(refactoring.kind)));
        }
      });
    });
  }

  void generateRequestsIndex(Iterable<Request> requests) {
    h5(() => write("Requests"));
    element('ul', {}, () {
      for (var request in requests) {
        if (!request.experimental) {
          element(
              'li',
              {},
              () => link('request_${request.longMethod}',
                  () => write(request.method)));
        }
      }
    });
  }

  void generateTableOfContents() {
    for (var domain in api.domains.where((domain) => !domain.experimental)) {
      if (domain.experimental) continue;

      writeln();

      p(() {
        link('domain_${domain.name}', () {
          write(_toTitleCase(domain.name));
        });
      });

      ul(() {
        for (Request request in domain.requests) {
          if (request.experimental) continue;

          li(() {
            link('request_${request.longMethod}', () {
              write(request.longMethod);
            }, request.deprecated ? {'class': 'deprecated'} : null);
          });
          writeln();
        }
      });

      writeln();
    }
  }

  void generateTypesIndex(Set<String> types) {
    h3(() {
      write("Types");
      write(' (');
      link('types', () => write('\u2191'));
      write(')');
    });
    List<String> sortedTypes = types.toList();
    sortedTypes.sort();
    element('div', {'class': 'subindex'}, () {
      element('ul', {}, () {
        for (var type in sortedTypes) {
          element('li', {}, () => link('type_$type', () => write(type)));
        }
      });
    });
  }

  void javadocParams(TypeObject typeObject) {
    if (typeObject != null) {
      for (TypeObjectField field in typeObject.fields) {
        hangingIndent(() {
          write('@param ${field.name} ');
          translateHtml(field.html, squashParagraphs: true);
        });
      }
    }
  }

  /**
   * Generate a description of [type] using [TypeVisitor].
   *
   * If [shortDesc] is non-null, the output is prefixed with this string
   * and a colon.
   *
   * If [typeForBolding] is supplied, then fields in this type are shown in
   * boldface.
   */
  void showType(String shortDesc, TypeDecl type, [TypeObject typeForBolding]) {
    Set<String> fieldsToBold = new Set<String>();
    if (typeForBolding != null) {
      for (TypeObjectField field in typeForBolding.fields) {
        fieldsToBold.add(field.name);
      }
    }
    pre(() {
      if (shortDesc != null) {
        write('$shortDesc: ');
      }
      TypeVisitor typeVisitor =
          new TypeVisitor(api, fieldsToBold: fieldsToBold);
      addAll(typeVisitor.collectHtml(() {
        typeVisitor.visitTypeDecl(type);
      }));
    });
  }

  /**
   * Copy the contents of the given HTML element, translating the special
   * elements that define the API appropriately.
   */
  void translateHtml(dom.Element html, {bool squashParagraphs: false}) {
    for (dom.Node node in html.nodes) {
      if (node is dom.Element) {
        if (squashParagraphs && node.localName == 'p') {
          translateHtml(node, squashParagraphs: squashParagraphs);
          continue;
        }
        switch (node.localName) {
          case 'domains':
            generateDomainsHeader();
            break;
          case 'domain':
            visitDomain(apiMappings.domains[node]);
            break;
          case 'head':
            head(() {
              translateHtml(node, squashParagraphs: squashParagraphs);
              element('link', {
                'rel': 'stylesheet',
                'href':
                    'https://fonts.googleapis.com/css?family=Source+Code+Pro|Roboto:500,400italic,300,400',
                'type': 'text/css'
              });
              element('style', {}, () {
                writeln(stylesheet);
              });
            });
            break;
          case 'refactorings':
            visitRefactorings(api.refactorings);
            break;
          case 'types':
            visitTypes(api.types);
            break;
          case 'version':
            translateHtml(node, squashParagraphs: squashParagraphs);
            break;
          case 'toc':
            generateTableOfContents();
            break;
          case 'index':
            generateIndex();
            break;
          default:
            if (!ApiReader.specialElements.contains(node.localName)) {
              element(node.localName, node.attributes, () {
                translateHtml(node, squashParagraphs: squashParagraphs);
              });
            }
        }
      } else if (node is dom.Text) {
        String text = node.text;
        write(text);
      }
    }
  }

  @override
  void visitApi() {
    Iterable<TypeDefinition> apiTypes =
        api.types.where((TypeDefinition td) => !td.experimental);
    definedTypes = apiTypes.map((TypeDefinition td) => td.name).toSet();

    html(() {
      translateHtml(api.html);
    });
  }

  @override
  void visitDomain(Domain domain) {
    if (domain.experimental) {
      return;
    }
    h2('domain', () {
      anchor('domain_${domain.name}', () {
        write('${domain.name} domain');
      });
    });
    translateHtml(domain.html);
    if (domain.requests.isNotEmpty) {
      h3(() {
        write('Requests');
      });
      dl(() {
        domain.requests.forEach(visitRequest);
      });
    }
    if (domain.notifications.isNotEmpty) {
      h3(() {
        write('Notifications');
      });
      dl(() {
        domain.notifications.forEach(visitNotification);
      });
    }
  }

  @override
  void visitNotification(Notification notification) {
    dt('notification', () {
      anchor('notification_${notification.longEvent}', () {
        write(notification.longEvent);
      });
    });
    dd(() {
      box(() {
        showType(
            'notification', notification.notificationType, notification.params);
      });
      translateHtml(notification.html);
      describePayload(notification.params, 'parameters:');
    });
  }

  @override
  visitRefactoring(Refactoring refactoring) {
    dt('refactoring', () {
      write(refactoring.kind);
    });
    dd(() {
      translateHtml(refactoring.html);
      describePayload(refactoring.feedback, 'Feedback:', force: true);
      describePayload(refactoring.options, 'Options:', force: true);
    });
  }

  @override
  void visitRefactorings(Refactorings refactorings) {
    translateHtml(refactorings.html);
    dl(() {
      super.visitRefactorings(refactorings);
    });
  }

  @override
  void visitRequest(Request request) {
    if (request.experimental) {
      return;
    }
    dt(request.deprecated ? 'request deprecated' : 'request', () {
      anchor('request_${request.longMethod}', () {
        write(request.longMethod);
      });
    });
    dd(() {
      box(() {
        showType('request', request.requestType, request.params);
        br();
        showType('response', request.responseType, request.result);
      });
      translateHtml(request.html);
      describePayload(request.params, 'parameters:');
      describePayload(request.result, 'returns:');
    });
  }

  @override
  void visitTypeDefinition(TypeDefinition typeDefinition) {
    if (typeDefinition.experimental) {
      return;
    }
    dt(
        typeDefinition.deprecated
            ? 'typeDefinition deprecated'
            : 'typeDefinition', () {
      anchor('type_${typeDefinition.name}', () {
        write('${typeDefinition.name}: ');
        TypeVisitor typeVisitor = new TypeVisitor(api, short: true);
        addAll(typeVisitor.collectHtml(() {
          typeVisitor.visitTypeDecl(typeDefinition.type);
        }));
      });
    });
    dd(() {
      translateHtml(typeDefinition.html);
      visitTypeDecl(typeDefinition.type);
    });
  }

  @override
  void visitTypeEnum(TypeEnum typeEnum) {
    dl(() {
      super.visitTypeEnum(typeEnum);
    });
  }

  @override
  void visitTypeEnumValue(TypeEnumValue typeEnumValue) {
    bool isDocumented = false;
    for (dom.Node node in typeEnumValue.html.nodes) {
      if ((node is dom.Element && node.localName != 'code') ||
          (node is dom.Text && node.text.trim().isNotEmpty)) {
        isDocumented = true;
        break;
      }
    }
    dt(typeEnumValue.deprecated ? 'value deprecated' : 'value', () {
      write(typeEnumValue.value);
    });
    if (isDocumented) {
      dd(() {
        translateHtml(typeEnumValue.html);
      });
    }
  }

  @override
  void visitTypeList(TypeList typeList) {
    visitTypeDecl(typeList.itemType);
  }

  @override
  void visitTypeMap(TypeMap typeMap) {
    visitTypeDecl(typeMap.valueType);
  }

  @override
  void visitTypeObject(TypeObject typeObject) {
    dl(() {
      super.visitTypeObject(typeObject);
    });
  }

  @override
  void visitTypeObjectField(TypeObjectField typeObjectField) {
    dt('field', () {
      b(() {
        if (typeObjectField.deprecated) {
          span('deprecated', () {
            write(typeObjectField.name);
          });
        } else {
          write(typeObjectField.name);
        }
        if (typeObjectField.value != null) {
          write(' = ${JSON.encode(typeObjectField.value)}');
        } else {
          write(': ');
          TypeVisitor typeVisitor = new TypeVisitor(api, short: true);
          addAll(typeVisitor.collectHtml(() {
            typeVisitor.visitTypeDecl(typeObjectField.type);
          }));
          if (typeObjectField.optional) {
            gray(() => write(' (optional)'));
          }
        }
      });
    });
    dd(() {
      translateHtml(typeObjectField.html);
    });
  }

  @override
  void visitTypeReference(TypeReference typeReference) {}

  @override
  void visitTypes(Types types) {
    translateHtml(types.html);
    dl(() {
      List<TypeDefinition> sortedTypes = types.toList();
      sortedTypes.sort((TypeDefinition first, TypeDefinition second) =>
          first.name.compareTo(second.name));
      sortedTypes.forEach(visitTypeDefinition);
    });
  }
}

/**
 * Visitor that generates a compact representation of a type, such as:
 *
 * {
 *   "id": String
 *   "error": optional Error
 *   "result": {
 *     "version": String
 *   }
 * }
 */
class TypeVisitor extends HierarchicalApiVisitor
    with HtmlMixin, HtmlCodeGenerator {
  /**
   * Set of fields which should be shown in boldface, or null if no field
   * should be shown in boldface.
   */
  final Set<String> fieldsToBold;

  /**
   * True if a short description should be generated.  In a short description,
   * objects are shown as simply "object", and enums are shown as "String".
   */
  final bool short;

  TypeVisitor(Api api, {this.fieldsToBold, this.short: false}) : super(api);

  @override
  void visitTypeEnum(TypeEnum typeEnum) {
    if (short) {
      write('String');
      return;
    }
    writeln('enum {');
    indent(() {
      for (TypeEnumValue value in typeEnum.values) {
        writeln(value.value);
      }
    });
    write('}');
  }

  @override
  void visitTypeList(TypeList typeList) {
    write('List<');
    visitTypeDecl(typeList.itemType);
    write('>');
  }

  @override
  void visitTypeMap(TypeMap typeMap) {
    write('Map<');
    visitTypeDecl(typeMap.keyType);
    write(', ');
    visitTypeDecl(typeMap.valueType);
    write('>');
  }

  @override
  void visitTypeObject(TypeObject typeObject) {
    if (short) {
      write('object');
      return;
    }
    writeln('{');
    indent(() {
      for (TypeObjectField field in typeObject.fields) {
        write('"');
        if (fieldsToBold != null && fieldsToBold.contains(field.name)) {
          b(() {
            write(field.name);
          });
        } else {
          write(field.name);
        }
        write('": ');
        if (field.value != null) {
          write(JSON.encode(field.value));
        } else {
          if (field.optional) {
            gray(() {
              write('optional');
            });
            write(' ');
          }
          visitTypeDecl(field.type);
        }
        writeln();
      }
    });
    write('}');
  }

  @override
  void visitTypeReference(TypeReference typeReference) {
    String displayName = typeReference.typeName;
    if (api.types.containsKey(typeReference.typeName)) {
      link('type_${typeReference.typeName}', () {
        write(displayName);
      });
    } else {
      write(displayName);
    }
  }

  @override
  void visitTypeUnion(TypeUnion typeUnion) {
    bool verticalBarNeeded = false;
    for (TypeDecl choice in typeUnion.choices) {
      if (verticalBarNeeded) {
        write(' | ');
      }
      visitTypeDecl(choice);
      verticalBarNeeded = true;
    }
  }
}
