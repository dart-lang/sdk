// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A script to assist in documenting the difference between the dart:html API
 * and the old DOM API.
 */
#library('renames');

#import('../../../frog/lang.dart');
#import('../../../frog/file_system_node.dart');
#import('../../../frog/file_system.dart');
#import('../../../utils/dartdoc/dartdoc.dart');

void main() {
  HtmlDiff.initWorld('../../frog', new NodeFileSystem());
  initializeDartDoc();
  var diff = new HtmlDiff();
  diff.run();

  diff.domToDart.forEach((domMember, htmlMember) {
    if (domMember.name != htmlMember.name) {
      var domTypeName = domMember.declaringType.name;
      var htmlTypeName = htmlMember.declaringType.name.
        replaceFirst('WrappingImplementation', '');
      var htmlName = '$htmlTypeName.${htmlMember.name}';
      if (htmlMember.isConstructor || htmlMember.isFactory) {
        final separator = htmlMember.name == '' ? '' : '.';
        htmlName = 'new $htmlTypeName$separator${htmlMember.name}';
      }
      print('$domTypeName.${domMember.name} -> ${htmlName}');
    }
  });

  for (var type in world.dom.types.getValues()) {
    if (type.name == null) continue;
    if (type.definition is FunctionTypeDefinition) continue;
    for (var member in type.members.getValues()) {
      if (!member.isPrivate && member.name != 'typeName' &&
          !diff.domToDart.containsKey(member) &&
          (member is MethodMember || member is PropertyMember)) {
        print('No dart:html wrapper for ${type.name}.${member.name}');
      }
    }
  }
}

class HtmlDiff {
  final Map<Member, Member> domToDart;

  static void initWorld(String frogDir, FileSystem files) {
    parseOptions(frogDir, [] /* args */, files);
    initializeWorld(files);
    world.processScript('dart:html');
    world.resolveAll();
  }

  HtmlDiff() : domToDart = <Member, Member>{};

  void run() {
    final htmlLib = world.libraries['dart:html'];
    for (var htmlType in htmlLib.types.getValues()) {
      final domType = htmlToDomType(htmlType);
      final members = new List.from(htmlType.members.getValues());
      members.addAll(htmlType.constructors.getValues());
      htmlType.factories.forEach((f) => members.add(f));
      for (var member in members) {
        htmlToDomMembers(member, domType).forEach((m) => domToDart[m] = member);
      }
    }
  }

  Type htmlToDomType(Type htmlType) {
    if (htmlType.name == null) return;
    final tags = _getTags(findComment(htmlType.span));

    if (tags.containsKey('domName')) {
      final domName = tags['domName'];
      if (domName == 'none') return;
      // DOMWindow is Chrome-specific, so we don't use it in our annotations.
      if (domName == 'Window') domName = 'DOMWindow';
      final domType = world.dom.types[domName];
      if (domType == null) print('Warning: no dart:dom type named $domName');
      return domType;
    } else {
      if (!htmlType.name.endsWith('WrappingImplementation')) return;
      final domName = htmlType.name.replaceFirst('WrappingImplementation', '');
      var domType = world.dom.types[domName];
      if (domType == null && domName.endsWith('Element')) {
        domType = world.dom.types['HTML$domName'];
      }
      if (domType == null) domType = world.dom.types['WebKit$domName'];
      if (domType == null) {
        print('Warning: no dart:dom type matches dart:html ${htmlType.name}');
      }
      return domType;
    }
  }

  Set<Member> htmlToDomMembers(Member htmlMember, Type domType) {
    if (htmlMember.isPrivate) return new Set();
    if (htmlMember is MethodMember) {
      final tags = _getTags(findComment(htmlMember.span));
      if (tags.containsKey('domName')) {
        final domName = tags['domName'];
        if (domName == 'none') return new Set();
        return _membersFromName(domName, domType, world.dom);
      }
      if (domType == null) return new Set();
      if (htmlMember.definition == null) return new Set();
      if (htmlMember.name == 'get:on') {
        final members = _members(domType.members['addEventListener']);
        members.addAll(_members(domType.members['dispatchEvent']));
        members.addAll(_members(domType.members['removeEventListener']));
        return members;
      }
      if (htmlMember.isFactory && htmlMember.name == '' &&
          domType.name.endsWith('Event')) {
        return _members(domType.members['init${domType.name}']);
      }
      return _members(_getDomMember(htmlMember.definition.body, domType));
    } else if (htmlMember is PropertyMember) {
      final members = new Set();
      if (htmlMember.getter != null) {
        members.addAll(htmlToDomMembers(htmlMember.getter, domType));
      }
      if (htmlMember.setter != null) {
        members.addAll(htmlToDomMembers(htmlMember.setter, domType));
      }
      return members;
    } else {
      return new Set();
    }
  }

  Set<Member> _membersFromName(String name, Type defaultType, Library library) {
    if (!name.contains('.', 0)) {
      if (defaultType == null) {
        print('Warning: no default type for ${name}');
        return new Set();
      }
      final member = defaultType.members[name];
      if (member == null) {
        print('Warning: no member ${defaultType.name}.${name}');
      }
      return _members(member);
    }

    final splitName = name.split('.');
    if (splitName.length != 2) {
      print('Warning: invalid member name ${name}');
      return new Set();
    }
    final type = library.types[splitName[0]];
    if (type == null) {
      print('Warning: no ${library.name} type named ${splitName[0]}');
      return new Set();
    }
    final member = type.members[splitName[1]];
    if (member == null) {
      print('Warning: no member named $name');
    }
    return _members(member);
  }

  Set<Member> _members(Member m) => m == null ? new Set() : new Set.from([m]);

  Member _getDomMember(Statement stmt, Type domType) {
    if (stmt is BlockStatement) {
      final body = stmt.body.filter((s) => !_ignorableStatement(s));
      if (body.length != 1) return;
      return _getDomMember(stmt.body[0], domType);
    } else if (stmt is ReturnStatement) {
      return _domMemberFromExpression(stmt.value, domType);
    } else if (stmt is ExpressionStatement) {
      return _domMemberFromExpression(stmt.body, domType);
    } else if (stmt is TryStatement) {
      return _getDomMember(stmt.body, domType);
    } else if (stmt is IfStatement) {
      final trueMember = _getDomMember(stmt.trueBranch, domType);
      final falseMember = _getDomMember(stmt.falseBranch, domType);
      if (stmt.falseBranch == null || trueMember == falseMember) {
        return trueMember;
      }
    }
  }

  /**
   * Whether a statement can be ignored for the purpose of determining the DOM
   * name of the enclosing method. The Webkit-to-Dart conversion process leaves
   * behind various throws and returns that we want to ignore.
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

  Member _domMemberFromExpression(Expression expr, Type domType) {
    if (expr is BinaryExpression && expr.op.kind == TokenKind.ASSIGN) {
      return _domMemberFromExpression(expr.x, domType);
    } else if (expr is CallExpression) {
      if (expr.target is DotExpression && expr.target.self is VarExpression &&
          expr.target.self.name.name == 'LevelDom' &&
          (expr.target.name.name.startsWith('wrap') ||
           expr.target.name.name == 'unwrap')) {
        return _domMemberFromExpression(expr.arguments[0].value, domType);
      }
      return _domMemberFromExpression(expr.target, domType);
    } else if (expr is DotExpression) {
      if (expr.self is NewExpression && expr.name.name == '_wrap' &&
          expr.self.arguments.length == 1) {
        return _domMemberFromExpression(expr.self.arguments[0].value, domType);
      } else if (expr.self is VarExpression && expr.self.name.name == '_ptr') {
        return domType.members[expr.name.name];
      }
      final base = _domMemberFromExpression(expr.self, domType);
      if (base != null && base.returnType != null) {
        return base.returnType.members[expr.name.name];
      }
    } else if (expr is NewExpression && expr.arguments.length == 1) {
      return _domMemberFromExpression(expr.arguments[0].value, domType);
    } else {
      return null;
    }
  }

  Map<String, String> _getTags(String comment) {
    if (comment == null) return const <String, String>{};
    final re = new RegExp("@([a-zA-Z]+) ([^;]+)(?:;|\$)");
    final tags = <String, String>{};
    for (var m in re.allMatches(comment.trim())) {
      tags[m[1]] = m[2];
    }
    return tags;
  }
}
