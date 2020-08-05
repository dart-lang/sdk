import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'dart:core';

/// Replaces invocation of Map factory constructors with
/// factories of VM-specific classes.
/// new Map() => new _InternalLinkedHashMap<K, V>()
/// new Map.identity() => new LinkedHashMap.identity() => new _CompactLinkedIdentityHashMap<K, V>();
/// new Map.unmodifiable() => new UnmodifiableMapView<K, V>(new Map<K, V>.from(other))
/// new LinkedHashMap<K, V>() => new _InternalLinkedHashMap<K, V>()
/// new LinkedHashMap<K, V>(hashCode, equals) => new _CompactLinkedIdentityHashMap<K, V>()
/// new LinkedHashMap<K, V>(hashCode, equals, isValidKey) => new _CompactLinkedCustomHashMap<K, V>(equals, hashCode, isValidKey)
class MapFactorySpecializer {
  final Procedure _defaultMapFactory;
  final Procedure _mapIdentityFactory;
  final Procedure _mapUnmodifiableFactory;
  final Procedure _mapFromFactory;
  final Procedure _linkedHashMapFromFactory;
  final Procedure _linkedHashMapDefaultFactory;
  final Constructor _internalLinkedHashMapConstructor;
  final Constructor _compactLinkedIdentityHashMapConstructor;
  final Constructor _unmodifiableMapViewConstructor;
  final Constructor _compactLinkedCustomHashMapConstructor;

  final Procedure _identityHashCode;
  final Procedure _identical;
  final Procedure _defaultEqual;
  final Procedure _defaultHashCode;

  MapFactorySpecializer(CoreTypes coreTypes)
      : _defaultMapFactory = assertNotNull(
          coreTypes.index.getMember(
            'dart:core',
            'Map',
            '',
          ),
        ),
        _mapIdentityFactory = assertNotNull(
          coreTypes.index.getMember(
            'dart:core',
            'Map',
            'identity',
          ),
        ),
        _mapUnmodifiableFactory = assertNotNull(
          coreTypes.index.getMember(
            'dart:core',
            'Map',
            'unmodifiable',
          ),
        ),
        _mapFromFactory = assertNotNull(
          coreTypes.index.getMember(
            'dart:core',
            'Map',
            'from',
          ),
        ),
        _linkedHashMapFromFactory = assertNotNull(
          coreTypes.index.getMember(
            'dart:collection',
            'LinkedHashMap',
            'from',
          ),
        ),
        _linkedHashMapDefaultFactory = assertNotNull(
          coreTypes.index.getMember(
            'dart:collection',
            'LinkedHashMap',
            '',
          ),
        ),
        _internalLinkedHashMapConstructor = assertNotNull(
          coreTypes.index.getMember(
            'dart:collection',
            '_InternalLinkedHashMap',
            '',
          ),
        ),
        _compactLinkedIdentityHashMapConstructor = assertNotNull(
          coreTypes.index.getMember(
            'dart:collection',
            '_CompactLinkedIdentityHashMap',
            '',
          ),
        ),
        _compactLinkedCustomHashMapConstructor = assertNotNull(
          coreTypes.index.getMember(
            'dart:collection',
            '_CompactLinkedCustomHashMap',
            '',
          ),
        ),
        _unmodifiableMapViewConstructor = assertNotNull(
          coreTypes.index.getMember(
            'dart:collection',
            'UnmodifiableMapView',
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

  TreeNode transformStaticInvocation(StaticInvocation node) {
    final target = node.target;
    final args = node.arguments;
    if (target == _defaultMapFactory) {
      assert(args.positional.length == 0);
      // new Map() => new _InternalLinkedHashMap<K, V>()
      return ConstructorInvocation(
        _internalLinkedHashMapConstructor,
        Arguments([], types: args.types),
      )..fileOffset = node.fileOffset;
    } else if (target == _mapIdentityFactory) {
      assert(args.positional.length == 0);
      // new Map.identity() => new _CompactLinkedIdentityHashMap<K, V>();
      return ConstructorInvocation(
        _compactLinkedIdentityHashMapConstructor,
        Arguments([], types: args.types),
      )..fileOffset = node.fileOffset;
    } else if (target == _mapUnmodifiableFactory) {
      assert(args.positional.length == 1);
      final other = args.positional[0];
      assert(other is Map);
      // new Map.unmodifiable(other) => new UnmodifiableMapView<K, V>(new Map<K, V>.from(other))
      return ConstructorInvocation(
        _unmodifiableMapViewConstructor,
        Arguments([
          StaticInvocation(
            _linkedHashMapFromFactory,
            Arguments([other], types: args.types),
          )..fileOffset = node.fileOffset,
        ], types: args.types),
      )..fileOffset = node.fileOffset;
    } else if (target == _linkedHashMapDefaultFactory) {
      if (args.named.isEmpty) {
        return ConstructorInvocation(
          _internalLinkedHashMapConstructor,
          Arguments([], types: args.types),
        )..fileOffset = node.fileOffset;
      }

      TreeNode getFieldFromArgs(String name) {
        return args.named.firstWhere(
          (NamedExpression e) => e.name == name,
          orElse: () => null,
        );
      }

      NamedExpression equals = getFieldFromArgs('equals');
      NamedExpression hashCode = getFieldFromArgs('hashCode');
      NamedExpression isValidKey = getFieldFromArgs('isValidKey');
      if (isValidKey == null) {
        if (hashCode == null) {
          if (equals == null) {
            return ConstructorInvocation(
              _internalLinkedHashMapConstructor,
              Arguments([], types: args.types),
            )..fileOffset = node.fileOffset;
          }
          hashCode = NamedExpression('hashCode', StaticGet(_defaultHashCode));
        } else {
          if (_identical == equals && _identityHashCode == hashCode) {
            return ConstructorInvocation(
              _compactLinkedIdentityHashMapConstructor,
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
        _compactLinkedCustomHashMapConstructor,
        Arguments([
          equals?.value, hashCode?.value, isValidKey?.value,
        ], types: args.types),
      )..fileOffset = node.fileOffset;
    }
    return node;
  }
}
