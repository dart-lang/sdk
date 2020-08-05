import 'package:kernel/core_types.dart';
import 'package:kernel/ast.dart';

/// Replaces invocation of Map factory constructors with
/// factories of VM-specific classes.
/// new Set() => new _CompactLinkedHashSet<K, V>()
/// new Set.identity() => new LinkedHashSet.identity() => new _CompactLinkedIdentityHashSet<E>();
/// new LinkedHashSet<E>() => new _CompactLinkedHashSet<E>()
/// new LinkedHashSet<E>(hashCode, equals) => new _CompactLinkedIdentityHashSet<E>()
/// new LinkedHashSet<E>(hashCode, equals, isValidKey) => new _CompactLinkedCustomHashSet<E>(equals, hashCode, isValidKey)
class SetFactorySpecializer {
  final Procedure _defaultSetFactory;
  final Procedure _setIdentityFactory;
  final Procedure _linkedHashSetDefaultFactory;
  final Constructor _compactLinkedHashSetConstructor;
  final Constructor _compactLinkedIdentityHashSetConstructor;
  final Constructor _compactLinkedCustomHashSetConstructor;
  final Procedure _identityHashCode;
  final Procedure _identical;
  final Procedure _defaultEqual;
  final Procedure _defaultHashCode;

  SetFactorySpecializer(CoreTypes coreTypes)
      : _defaultSetFactory = assertNotNull(
          coreTypes.index.getMember(
            'dart:core',
            'Set',
            '',
          ),
        ),
        _setIdentityFactory = assertNotNull(
          coreTypes.index.getMember(
            'dart:core',
            'Set',
            'identity',
          ),
        ),
        _linkedHashSetDefaultFactory = assertNotNull(
          coreTypes.index.getMember(
            'dart:collection',
            'LinkedHashSet',
            '',
          ),
        ),
        _compactLinkedHashSetConstructor = assertNotNull(
          coreTypes.index.getMember(
            'dart:collection',
            '_CompactLinkedHashSet',
            '',
          ),
        ),
        _compactLinkedIdentityHashSetConstructor = assertNotNull(
          coreTypes.index.getMember(
            'dart:collection',
            '_CompactLinkedIdentityHashSet',
            '',
          ),
        ),
        _compactLinkedCustomHashSetConstructor = assertNotNull(
          coreTypes.index.getMember(
            'dart:collection',
            '_CompactLinkedCustomHashSet',
            '',
          ),
        ),
        _identityHashCode = assertNotNull(
          coreTypes.index.getTopLevelMember(
            'dart:core',
            'identityHashCode',
          ),
        ),
        _identical = assertNotNull(
          coreTypes.index.getTopLevelMember(
            'dart:core',
            'identical',
          ),
        ),
        _defaultEqual = assertNotNull(
          coreTypes.index.getTopLevelMember(
            'dart:collection',
            '_defaultEquals',
          ),
        ),
        _defaultHashCode = assertNotNull(
          coreTypes.index.getTopLevelMember(
            'dart:collection',
            '_defaultHashCode',
          ),
        );

  static T assertNotNull<T>(T t) {
    assert(t != null);
    return t;
  }

  TreeNode transformStaticInvocation(TreeNode origin) {
    if (origin is! StaticInvocation) {
      return origin;
    }
    final node = origin as StaticInvocation;
    final target = node.target;
    final args = node.arguments;
    if (target == _defaultSetFactory) {
      assert(args.positional.isEmpty);
      return ConstructorInvocation(
        _compactLinkedHashSetConstructor,
        Arguments([], types: args.types),
      )..fileOffset = node.fileOffset;
    } else if (target == _setIdentityFactory) {
      assert(args.positional.isEmpty);
      return ConstructorInvocation(
        _compactLinkedIdentityHashSetConstructor,
        Arguments([], types: args.types),
      )..fileOffset = node.fileOffset;
    } else if (target == _linkedHashSetDefaultFactory) {
      if (args.named.isEmpty) {
        return ConstructorInvocation(
          _compactLinkedHashSetConstructor,
          Arguments([], types: args.types),
        );
      }

      TreeNode getFieldFromArgs(String name) {
        return args.named.firstWhere(
              (NamedExpression e) => e.name == name,
          orElse: () => null,
        );
      }

      Procedure getConstProcedure(ConstantExpression expr) {
        return (expr.constant as TearOffConstant).procedure;
      }
      NamedExpression equals = getFieldFromArgs('equals');
      NamedExpression hashCode = getFieldFromArgs('hashCode');
      NamedExpression isValidKey = getFieldFromArgs('isValidKey');
      if (isValidKey == null) {
        if (hashCode == null) {
          if (equals == null) {
            return ConstructorInvocation(
              _compactLinkedHashSetConstructor,
              Arguments([], types: args.types),
            )..fileOffset = node.fileOffset;
          }
          hashCode = NamedExpression('hashCode', StaticGet(_defaultHashCode));
        } else {
          if (equals.value is ConstantExpression &&
              hashCode.value is ConstantExpression &&
              _identical == getConstProcedure(equals.value) &&
              _identityHashCode == getConstProcedure(hashCode.value)
          ) {
            return ConstructorInvocation(
              _compactLinkedIdentityHashSetConstructor,
              Arguments([], types: args.types),
            )..fileOffset = node.fileOffset;
          }
          equals = NamedExpression('equals', StaticGet(_defaultEqual));
        }
        isValidKey = NamedExpression('isValidKey', NullLiteral());
      } else {
        hashCode ??= NamedExpression('hashCode', StaticGet(_defaultHashCode));
        equals ??= NamedExpression('equals', StaticGet(_defaultEqual));
      }

      return ConstructorInvocation(
        _compactLinkedCustomHashSetConstructor,
        Arguments([
          equals?.value, hashCode?.value, isValidKey?.value,
        ], types: args.types),
      )..fileOffset = node.fileOffset;
    }
    return node;
  }
}
