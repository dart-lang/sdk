// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A script to assist in documenting the difference between the dart:html API
 * and the old DOM API.
 */
#library('html_diff');

#import('dart:coreimpl');
#import('../../frog/lang.dart');
#import('../../frog/file_system_vm.dart');
#import('../../frog/file_system.dart');
#import('../../lib/dartdoc/dartdoc.dart');

/**
 * A class for computing a many-to-many mapping between the types and members in
 * `dart:dom` and `dart:html`. This mapping is based on two indicators:
 *
 *   1. Auto-detected wrappers. Most `dart:html` types correspond
 *      straightforwardly to a single `dart:dom` type, and have the same name.
 *      In addition, most `dart:html` methods just call a single `dart:dom`
 *      method. This class detects these simple correspondences automatically.
 *
 *   2. Manual annotations. When it's not clear which `dart:dom` items a given
 *      `dart:html` item corresponds to, the `dart:html` item can be
 *      annotated in the documentation comments using the `@domName` annotation.
 *
 * The `@domName` annotations for types and members are of the form `@domName
 * NAME(, NAME)*`, where the `NAME`s refer to the `dart:dom` types/members that
 * correspond to the annotated `dart:html` type/member. `NAME`s on member
 * annotations can refer to either fully-qualified member names (e.g.
 * `Document.createElement`) or unqualified member names (e.g. `createElement`).
 * Unqualified member names are assumed to refer to members of one of the
 * corresponding `dart:dom` types.
 */
class HtmlDiff {
  /** A map from `dart:dom` members to corresponding `dart:html` members. */
  final Map<Member, Set<Member>> domToHtml;

  /** A map from `dart:html` members to corresponding `dart:dom` members. */
  final Map<Member, Set<Member>> htmlToDom;

  /** A map from `dart:dom` types to corresponding `dart:html` types. */
  final Map<Type, Set<Type>> domTypesToHtml;

  /** A map from `dart:html` types to corresponding `dart:dom` types. */
  final Map<Type, Set<Type>> htmlTypesToDom;

  final CommentMap comments;

  static Library dom;

  /**
   * Perform static initialization of [world]. This should be run before
   * calling [HtmlDiff.run].
   */
  static void initialize() {
    world.getOrAddLibrary('dart:dom');
    world.getOrAddLibrary('dart:html');
    world.resolveAll();
    dom = world.libraries['dart:dom'];
  }

  HtmlDiff() :
    domToHtml = new Map<Member, Set<Member>>(),
    htmlToDom = new Map<Member, Set<Member>>(),
    domTypesToHtml = new Map<Type, Set<Type>>(),
    htmlTypesToDom = new Map<Type, Set<Type>>(),
    comments = new CommentMap();

  /**
   * Computes the `dart:dom` to `dart:html` mapping, and places it in
   * [domToHtml], [htmlToDom], [domTypesToHtml], and [htmlTypesToDom]. Before
   * this is run, Frog should be initialized (via [parseOptions] and
   * [initializeWorld]) and [HtmlDiff.initialize] should be called.
   */
  void run() {
    final htmlLib = world.libraries['dart:html'];
    for (var implType in htmlLib.types.getValues()) {
      final domTypes = htmlToDomTypes(implType);
      final htmlType = htmlImplToHtmlType(implType);
      if (htmlType == null) continue;

      htmlTypesToDom.putIfAbsent(htmlType, () => new Set()).addAll(domTypes);
      domTypes.forEach((t) =>
          domTypesToHtml.putIfAbsent(t, () => new Set()).add(htmlType));

      final members = new List.from(implType.members.getValues());
      members.addAll(implType.constructors.getValues());
      implType.factories.forEach((f) => members.add(f));
      members.forEach((m) => _addMemberDiff(m, domTypes));
    }
  }

  /**
   * Returns whether or not [domMember] (from `dart:dom`) and [htmlMember] (from
   * `dart:html`) have the same name from the user's perspective. The names are
   * the same if the type names and the member names are the same, but allowance
   * is made for `dart:dom` names that start with "HTML" or "WebKit", and for
   * `dart:html` properties that have the same name as fields in `dart:dom`.
   */
  bool sameName(Member domMember, Member htmlMember) {
    var domTypeName = domMember.declaringType.name;
    if (domTypeName == 'DOMWindow') domTypeName = 'Window';
    domTypeName = domTypeName.replaceFirst(new RegExp('^(HTML|WebKit)'), '');
    var htmlTypeName = htmlMember.declaringType.name;

    var domName = domMember.name;
    var htmlName = htmlMember.name;
    if (htmlName.startsWith('get:') || htmlName.startsWith('set:')) {
      htmlName = htmlName.substring(4);
    }

    return domTypeName == htmlTypeName && domName == htmlName;
  }

  /**
   * Records the `dart:dom` to `dart:html` mapping for [implMember] (from
   * `dart:html`). [domTypes] are the `dart:dom` [Type]s that correspond to
   * [implMember]'s defining [Type].
   */
  void _addMemberDiff(Member implMember, List<Type> domTypes) {
    if (implMember.isProperty) {
      if (implMember.canGet) _addMemberDiff(implMember.getter, domTypes);
      if (implMember.canSet) _addMemberDiff(implMember.setter, domTypes);
    }

    var domMembers = htmlToDomMembers(implMember, domTypes);
    var htmlMember = htmlImplToHtmlMember(implMember);
    if (htmlMember == null && !domMembers.isEmpty()) {
      print('Warning: dart:html member ${implMember.declaringType.name}.' +
          '${implMember.name} has no corresponding dart:html member.');
    }

    if (htmlMember == null) return;
    if (!domMembers.isEmpty()) htmlToDom[htmlMember] = domMembers;
    domMembers.forEach((m) =>
        domToHtml.putIfAbsent(m, () => new Set()).add(htmlMember));
  }

  /**
   * Returns the `dart:html` [Type] that corresponds to [implType] from
   * `dart:html`, or `null` if there is no such correspondence.
   */
  Type htmlImplToHtmlType(Type implType) {
    if (implType == null || implType.isTop || implType.interfaces.isEmpty() ||
        implType.interfaces[0].library.name != 'html') {
      return null;
    }

    return implType.interfaces[0];
  }

  /**
   * Returns the `dart:html` [Member] that corresponds to [implMember] from
   * `dart:html`, or `null` if there is no such correspondence.
   */
  Member htmlImplToHtmlMember(Member implMember) {
    var htmlType = htmlImplToHtmlType(implMember.declaringType);
    if (htmlType == null) return null;

    if (implMember.isConstructor || implMember.isFactory) {
      var constructor = htmlType.constructors[implMember.name];
      if (constructor != null) return constructor;

      // Look for a factory constructor whose type and name matches the member.
      return htmlType.factories.getFactoriesFor(implMember.name)[
          implMember.constructorName];
    }

    final getter = implMember.name.startsWith('get:');
    final setter = implMember.name.startsWith('set:');

    if (getter || setter) {
      // Use getMember to follow interface inheritance chains.
      var htmlProperty = htmlType.getMember(implMember.name.substring(4));

      if (htmlProperty == null) return null;

      // If it's a straight field, use that directly.
      if (htmlProperty.isField) return htmlProperty;

      // Otherwise, it's a property, so use the appropriate getter or setter.
      return getter ? htmlProperty.getter : htmlProperty.setter;
    }

    return htmlType.getMember(implMember.name);
  }

  /**
   * Returns the `dart:dom` [Type]s that correspond to [htmlType] from
   * `dart:html`. This can be the empty list if no correspondence is found.
   */
  List<Type> htmlToDomTypes(Type htmlType) {
    if (htmlType.name == null) return [];
    final tags = _getTags(comments.find(htmlType.span));

    if (tags.containsKey('domName')) {
      var domNames = map(tags['domName'].split(','), (s) => s.trim());
      if (domNames.length == 1 && domNames[0] == 'none') return [];
      return map(domNames, (domName) {
        // DOMWindow is Chrome-specific, so we don't use it in our annotations.
        if (domName == 'Window') domName = 'DOMWindow';
        final domType = dom.types[domName];
        if (domType == null) print('Warning: no dart:dom type named $domName');
        return domType;
      });
    } else {
      if (!htmlType.name.endsWith('WrappingImplementation')) return [];
      final domName = htmlType.name.replaceFirst('WrappingImplementation', '');
      var domType = dom.types[domName];
      if (domType == null && domName.endsWith('Element')) {
        domType = dom.types['HTML$domName'];
      }
      if (domType == null) domType = dom.types['WebKit$domName'];
      if (domType == null) {
        print('Warning: no dart:dom type matches dart:html ' +
            htmlType.name);
        return [];
      }
      return [domType];
    }
  }

  /**
   * Returns the `dart:dom` [Member]s that correspond to [htmlMember] from
   * `dart:html`. This can be the empty set if no correspondence is found.
   * [domTypes] are the `dart:dom` [Type]s that correspond to [implMember]'s
   * defining [Type].
   */
  Set<Member> htmlToDomMembers(Member htmlMember, List<Type> domTypes) {
    if (htmlMember.isPrivate || htmlMember is! MethodMember) return new Set();
    final tags = _getTags(comments.find(htmlMember.span));
    if (tags.containsKey('domName')) {
      final domNames = map(tags['domName'].split(','), (s) => s.trim());
      if (domNames.length == 1 && domNames[0] == 'none') return new Set();
      final members = new Set();
      domNames.forEach((name) {
        var nameMembers = _membersFromName(name, domTypes);
        if (nameMembers.isEmpty()) {
          if (name.contains('.')) {
            print('Warning: no member $name');
          } else {
            final options = Strings.join(
                map(domTypes, (t) => "${t.name}.$name"), ' or ');
            print('Warning: no member $options');
          }
        }
        members.addAll(nameMembers);
      });
      return members;
    }

    if (domTypes.isEmpty() || htmlMember.definition == null) return new Set();
    if (htmlMember.name == 'get:on') {
      final members = _membersFromName('addEventListener', domTypes);
      members.addAll(_membersFromName('dispatchEvent', domTypes));
      members.addAll(_membersFromName('removeEventListener', domTypes));
      return members;
    }

    if (htmlMember.isFactory && htmlMember.name == '' &&
        domTypes.length == 1 && domTypes[0].name.endsWith('Event')) {
      return _membersFromName('init${domTypes[0].name}', domTypes);
    }

    return _getDomMembers(htmlMember.definition.body, domTypes);
  }

  /**
   * Returns the `dart:dom` [Member]s that are indicated by [name]. [name] can
   * be either an unqualified member name (e.g. `createElement`), in which case
   * it's treated as the name of a member of one of [defaultTypes], or a
   * fully-qualified member name (e.g. `Document.createElement`), in which case
   * it's looked up in `dart:dom` and [defaultTypes] is ignored.
   */
  Set<Member> _membersFromName(String name, List<Type> defaultTypes) {
    if (!name.contains('.', 0)) {
      if (defaultTypes.isEmpty()) {
        print('Warning: no default type for ${name}');
        return new Set();
      }
      final members = new Set<Member>();
      defaultTypes.forEach((t) {
        if (t.members.containsKey(name)) members.add(t.members[name]);
      });
      return members;
    }

    final splitName = name.split('.');
    if (splitName.length != 2) {
      print('Warning: invalid member name ${name}');
      return new Set();
    }

    var typeName = splitName[0];
    if (typeName == 'Window') typeName = 'DOMWindow';

    final type = dom.types[typeName];
    if (type == null) return new Set();

    final member = type.members[splitName[1]];
    if (member == null) return new Set();

    return new Set.from([member]);
  }

  /**
   * Returns the `dart:dom` [Member]s that are referred to in [stmt]. This only
   * extracts references from relatively simple statements; methods containing
   * more complex wrappers should be manually annotated with `@domName`.
   *
   * [domTypes] are the `dart:dom` [Type]s that correspond to the current
   * [Member]'s defining [Type].
   */
  Set<Member> _getDomMembers(Statement stmt, List<Type> domTypes) {
    if (stmt is BlockStatement) {
      final body = stmt.body.filter((s) => !_ignorableStatement(s));
      if (body.length != 1) return new Set();
      return _getDomMembers(stmt.body[0], domTypes);
    } else if (stmt is ReturnStatement) {
      return _domMembersFromExpression(stmt.value, domTypes);
    } else if (stmt is ExpressionStatement) {
      return _domMembersFromExpression(stmt.body, domTypes);
    } else if (stmt is TryStatement) {
      return _getDomMembers(stmt.body, domTypes);
    } else if (stmt is IfStatement) {
      final members = _getDomMembers(stmt.trueBranch, domTypes);
      members.addAll(_getDomMembers(stmt.falseBranch, domTypes));
      return members;
    } else {
      return new Set();
    }
  }

  /**
   * Whether [stmt] can be ignored for the purpose of determining the DOM name
   * of the enclosing method. The Webkit-to-Dart conversion process leaves
   * behind various `throw`s and `return`s that we want to ignore.
   */
  bool _ignorableStatement(Statement stmt) {
    if (stmt is BlockStatement) {
      return Collections.every(stmt.body, (s) => _ignorableStatement(s));
    } else if (stmt is TryStatement) {
      return _ignorableStatement(stmt.body);
    } else if (stmt is IfStatement) {
      return _ignorableStatement(stmt.trueBranch) &&
        _ignorableStatement(stmt.falseBranch);
    } else if (stmt is ReturnStatement) {
      return stmt.value == null || stmt.value is ThisExpression;
    } else {
      return stmt is ThrowStatement;
    }
  }

  /**
   * Returns the `dart:dom` [Member]s that are referred to in [expr]. This only
   * extracts references from relatively simple expressions; methods containing
   * more complex wrappers should be manually annotated with `@domName`.
   *
   * [domTypes] are the `dart:dom` [Type]s that correspond to the current
   * [Member]'s defining [Type].
   */
  Set<Member> _domMembersFromExpression(Expression expr, List<Type> domTypes) {
    if (expr is BinaryExpression && expr.op.kind == TokenKind.ASSIGN) {
      return _domMembersFromExpression(expr.x, domTypes);
    } else if (expr is CallExpression) {
      if (expr.target is DotExpression && expr.target.self is VarExpression &&
          expr.target.self.name.name == 'LevelDom' &&
          (expr.target.name.name.startsWith('wrap') ||
           expr.target.name.name == 'unwrap')) {
        return _domMembersFromExpression(expr.arguments[0].value, domTypes);
      }
      return _domMembersFromExpression(expr.target, domTypes);
    } else if (expr is DotExpression) {
      if (expr.self is NewExpression && expr.name.name == '_wrap' &&
          expr.self.arguments.length == 1) {
        return _domMembersFromExpression(expr.self.arguments[0].value,
            domTypes);
      } else if (expr.self is VarExpression && expr.self.name.name == '_ptr') {
        return _membersFromName(expr.name.name, domTypes);
      }
      final bases = _domMembersFromExpression(expr.self, domTypes);
      return new Set.from(map(bases, (base) {
          if (base == null || base.returnType == null) return null;
          return base.returnType.members[expr.name.name];
        }).filter((m) => m != null));
    } else if (expr is NewExpression && expr.arguments.length == 1) {
      return _domMembersFromExpression(expr.arguments[0].value, domTypes);
    } else {
      return new Set();
    }
  }

  /**
   * Extracts a [Map] from tag names to values from [comment], which is parsed
   * from a Dart source file via dartdoc. Tags are of the form `@NAME VALUE`,
   * where `NAME` is alphabetic and `VALUE` can contain any character other than
   * `;`. Multiple tags can be separated by semicolons.
   *
   * At time of writing, the only tag that's used is `@domName`.
   */
  Map<String, String> _getTags(String comment) {
    if (comment == null) return const <String>{};
    final re = new RegExp("@([a-zA-Z]+) ([^;]+)(?:;|\$)");
    final tags = <String>{};
    for (var m in re.allMatches(comment.trim())) {
      tags[m[1]] = m[2];
    }
    return tags;
  }
}
