// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MemberSet {
  final String name;
  final List<Member> members;
  final bool isVar;

  bool _treatAsField;
  Type _returnTypeForGet;
  bool _preparedForSet = false;
  List<InvokeKey> _invokes;

  MemberSet(Member member, [bool isVar=false])
      : name = member.name, members = [member], isVar = isVar;

  toString() => '$name:${members.length}';

  /**
   * [jsname] should be called only when it is known that all the members have
   * the same jsname.  (The name safety pass can cause members of the same
   * MemberSet to have different jsnames.)
   */
  String get jsname() => members[0].jsname;

  void add(Member member) {
    // Only methods on classes "really exist" - so warn if we add others?
    members.add(member);
  }

  // TODO(jimhug): Better way to check for operator.
  bool get isOperator() => members[0].isOperator;

  bool get treatAsField() {
    if (_treatAsField == null) {
      // Must be all fields, all with the same jsname.
      _treatAsField = !isVar &&
          members.every((m) => m.isField && m.jsname == members[0].jsname);
    }
    return _treatAsField;
  }

  static Type unionTypes(Type t1, Type t2) {
    if (t1 == null) return t2;
    if (t2 == null) return t1;
    return Type.union(t1, t2);
  }

  /**
   * This needs to generate one of the following:
   * - target.name
   * - target.get$name()
   * - target.noSuchMethod(...)
   *
   * Can be treated as a field only if this is a properly resolved reference
   * and all resolve members are fields.
   */
  Value _get(CallingContext context, Node node, Value target) {
    if (members.length == 1 && !isVar) {
      return members[0]._get(context, node, target);
    }

    if (_returnTypeForGet == null) {
      for (var member in members) {
        if (!member.canGet) continue;
        if (!treatAsField) member.provideGetter();
        // TODO(jimhug): Need to make target less specific...
        var r = member._get(context, node, target);
        _returnTypeForGet = unionTypes(_returnTypeForGet, r.type);
      }
      if (_returnTypeForGet == null) {
        world.error('no valid getters for "$name"', node.span);
      }
    }

    if (_treatAsField) {
      return new Value(_returnTypeForGet,
        '${target.code}.$jsname', node.span);
    } else {
      return new Value(_returnTypeForGet,
        '${target.code}.${members[0].jsnameOfGetter}()', node.span);
    }
  }

  // TODO(jimhug): Return value of this method is unclear.
  Value _set(CallingContext context, Node node, Value target, Value value) {
    // If this is the global MemberSet from world, always bind dynamically.
    // Note: we need this for proper noSuchMethod and REPL behavior.
    if (members.length == 1 && !isVar) {
      return members[0]._set(context, node, target, value);
    }

    if (!_preparedForSet) {
      _preparedForSet = true;

      for (var member in members) {
        if (!member.canSet) continue;
        if (!treatAsField) member.provideSetter();
        // !!! Need more generic args to this call below.
        var r = member._set(context, node, target, value);
      }
    }

    if (treatAsField) {
      return new Value(value.type,
        '${target.code}.$jsname = ${value.code}', node.span);
    } else {
      return new Value(value.type,
        '${target.code}.${members[0].jsnameOfSetter}(${value.code})', node.span);
    }
  }

  Value invoke(CallingContext context, Node node, Value target,
      Arguments args) {
    if (members.length == 1 && !isVar) {
      return members[0].invoke(context, node, target, args);
    }

    var invokeKey = null;
    if (_invokes == null) {
      _invokes = [];
      invokeKey = null;
    } else {
      for (var ik in _invokes) {
        if (ik.matches(args)) {
          invokeKey = ik;
          break;
        }
      }
    }
    if (invokeKey == null) {
      invokeKey = new InvokeKey(args);
      _invokes.add(invokeKey);
      invokeKey.addMembers(members, context, target, args);
    }

    // TODO(jimhug): isOperator test is too lenient - misses opt chances
    if (invokeKey.needsVarCall || isOperator) {
      if (name == ':call') {
        return target._varCall(context, node, args);
      } else if (isOperator) {
        // TODO(jmesserly): make operators less special.
        return invokeSpecial(target, args, invokeKey.returnType);
      } else {
        return invokeOnVar(context, node, target, args);
      }
    } else {
      var code = '${target.code}.${jsname}(${args.getCode()})';
      return new Value(invokeKey.returnType, code, node.span);
    }
  }

  Value invokeSpecial(Value target, Arguments args, Type returnType) {
    assert(name.startsWith(':'));
    assert(!args.hasNames);
    // TODO(jimhug): We need to do this a little bit more like get and set on
    // properties.  We should check the set of members for something
    // like "requiresNativeIndexer" and "requiresDartIndexer" to
    // decide on a strategy.

    var argsString = args.getCode();
    // Most operator calls need to be emitted as function calls, so we don't
    // box numbers accidentally. Indexing is the exception.
    if (name == ':index' || name == ':setindex') {
      // TODO(jimhug): should not need this test both here and in invoke
      if (name == ':index') {
        world.gen.corejs.useIndex = true;
      } else if (name == ':setindex') {
        world.gen.corejs.useSetIndex = true;
      }
      return new Value(returnType, '${target.code}.$jsname($argsString)',
          target.span);
    } else {
      if (argsString.length > 0) argsString = ', $argsString';
      world.gen.corejs.useOperator(name);
      return new Value(returnType, '$jsname\$(${target.code}$argsString)',
          target.span);
    }
  }

  Value invokeOnVar(CallingContext context, Node node, Value target,
      Arguments args) {
    context.counters.dynamicMethodCalls++;

    var member = getVarMember(context, node, args);
    return member.invoke(context, node, target, args);
  }

  dumpAllMembers() {
    for (var member in members) {
      world.warning('hard-multi $name on ${member.declaringType.name}',
          member.span);
    }
  }

  VarMember getVarMember(CallingContext context, Node node, Arguments args) {
    if (world.objectType.varStubs == null) {
      world.objectType.varStubs = {};
    }

    var stubName = _getCallStubName(name, args);
    var stub = world.objectType.varStubs[stubName];
    if (stub == null) {
      // Ensure that we're making stub with all possible members of this name.
      // We need this canonicalization step because only one VarMemberSet can
      // live on Object.prototype
      // TODO(jmesserly): this is ugly--we're throwing away type information!
      // The right solution is twofold:
      //   1. put stubs on a more precise type when possible
      //   2. merge VarMemberSets together if necessary
      final mset = context.findMembers(name).members;

      final targets = mset.filter((m) => m.canInvoke(context, args));
      stub = new VarMethodSet(name, stubName, targets, args,
          _foldTypes(targets));
      world.objectType.varStubs[stubName] = stub;
    }
    return stub;
  }

  Type _foldTypes(List<Member> targets) =>
    reduce(map(targets, (t) => t.returnType), Type.union, world.varType);
}


class InvokeKey {
  int bareArgs;
  List<String> namedArgs;
  Type returnType;
  bool needsVarCall = false;

  InvokeKey(Arguments args) {
    bareArgs = args.bareCount;
    if (bareArgs != args.length) {
      namedArgs = args.getNames();
    }
  }

  bool matches(Arguments args) {
    if (namedArgs == null) {
      if (bareArgs != args.length) return false;
    } else {
      if (bareArgs + namedArgs.length != args.length) return false;
    }
    if (bareArgs != args.bareCount) return false;

    if (namedArgs == null) return true;

    for (int i = 0; i < namedArgs.length; i++) {
      if (namedArgs[i] != args.getName(bareArgs + i)) return false;
    }
    return true;
  }

  void addMembers(List<Member> members, CallingContext context, Value target,
      Arguments args) {
    for (var member in members) {
      // Check that this is a "perfect" match - or require a var call.
      // TODO(jimhug): Add support of "perfect matches" even with names.
      if (!(member.parameters.length == bareArgs && namedArgs == null)) {
        // If we have named arguments or a mismatch in the number of
        // formal and actual parameters, we go through a var call.
        needsVarCall = true;
      } else if (options.enableTypeChecks &&
                 member.isMethod &&
                 member.needsArgumentConversion(args)) {
        // The member we're adding is a method that needs argument
        // conversion, so we have to make it go through the var call
        // path to get the correct type checks inserted.
        needsVarCall = true;
      } else if (member.jsname != members[0].jsname) {
        // If the jsnames differ we need the var call since one of the stubs
        // will change the name.  Native methods can have different jsnames,
        // e.g.
        //     foo() native 'bar';
        needsVarCall = true;
      } else if (member.library.isDomOrHtml) {
        // TODO(jimhug): Egregious hack for isolates + DOM - see
        // Value._maybeWrapFunction for more details.
        for (var p in member.parameters) {
          if (p.type.getCallMethod() != null) {
            needsVarCall = true;
          }
        }
      }

      // TODO(jimhug): Should create a less specific version of args.
      if (member.canInvoke(context, args)) {
        if (member.isMethod) {
          returnType = MemberSet.unionTypes(returnType, member.returnType);
          member.declaringType.genMethod(member);
        } else {
          needsVarCall = true;
          returnType = world.varType;
        }
      }
    }
    if (returnType == null) {
      // TODO(jimhug): Warning here for no match anywhere in the world?
      returnType = world.varType;
    }
  }
}
