library kernel.transformations.flags;

import '../ast.dart';

/// Flags summarizing the kinds of AST nodes contained in a given member or
/// class, for speeding up transformations that only affect certain types of
/// nodes.
///
/// These are set by the frontend and the deserializer.
class TransformerFlag {
  /// The class or member contains 'super' calls, that is, one of the AST nodes
  /// [SuperPropertyGet], [SuperPropertySet], [SuperMethodInvocation].
  static const int superCalls = 1 << 0;

  // TODO(asgerf):  We could also add a flag for 'async' and will probably have
  // one for closures as well.
}
