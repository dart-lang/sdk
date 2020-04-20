// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common_elements.dart' show CommonElements;
import '../common/names.dart' show Identifiers, Selectors;
import '../elements/entities.dart';
import '../inferrer/types.dart';
import '../serialization/serialization.dart';

/// [NoSuchMethodRegistry] and [NoSuchMethodData] categorizes `noSuchMethod`
/// implementations.
///
/// If user code includes `noSuchMethod` implementations, type inference is
/// hindered because (for instance) any selector where the type of the
/// receiver is not known all implementations of `noSuchMethod` must be taken
/// into account when inferring the return type.
///
/// The situation can be ameliorated with some heuristics for disregarding some
/// `noSuchMethod` implementations during type inference. We can partition
/// `noSuchMethod` implementations into 4 categories.
///
/// Implementations in category A are the default implementations
/// `Object.noSuchMethod` and `Interceptor.noSuchMethod`.
///
/// Implementations in category B syntactically immediately throw, for example:
///
///     noSuchMethod(x) => throw 'not implemented'
///
/// Implementations in category C are not applicable, for example:
///
///     noSuchMethod() { /* missing parameter */ }
///     noSuchMethod(a, b) { /* too many parameters */ }
///
/// Implementations that do not fall into category A, B or C are in category D.
/// They are the only category of implementation that are considered during type
/// inference.
///
/// Implementations that syntactically just forward to the super implementation,
/// for example:
///
///     noSuchMethod(x) => super.noSuchMethod(x);
///
/// are in the same category as the superclass implementation. This covers a
/// common case, where users implement `noSuchMethod` with these dummy
/// implementations to avoid warnings.

/// Registry for collecting `noSuchMethod` implementations and categorizing them
/// into categories `A`, `B`, `C`, `D`.
abstract class NoSuchMethodRegistry {
  /// Register [noSuchMethodElement].
  void registerNoSuchMethod(FunctionEntity noSuchMethodElement);

  /// Categorizes the registered methods.
  void onQueueEmpty();

  /// `true` if a category `B` method has been seen so far.
  bool get hasThrowingNoSuchMethod;

  /// `true` if a category `D` method has been seen so far.
  bool get hasComplexNoSuchMethod;

  /// Closes the registry and returns data object used during type inference.
  NoSuchMethodData close();
}

class NoSuchMethodRegistryImpl implements NoSuchMethodRegistry {
  /// The implementations that fall into category A, described above.
  final Set<FunctionEntity> defaultImpls = new Set<FunctionEntity>();

  /// The implementations that fall into category B, described above.
  final Set<FunctionEntity> throwingImpls = new Set<FunctionEntity>();

  /// The implementations that fall into category C, described above.
  // TODO(johnniwinther): Remove this category when Dart 1 is no longer
  // supported.
  final Set<FunctionEntity> notApplicableImpls = new Set<FunctionEntity>();

  /// The implementations that fall into category D, described above.
  final Set<FunctionEntity> otherImpls = new Set<FunctionEntity>();

  /// The implementations that have not yet been categorized.
  final Set<FunctionEntity> _uncategorizedImpls = new Set<FunctionEntity>();

  /// The implementations that a forwarding syntax as defined by
  /// [NoSuchMethodResolver.hasForwardSyntax].
  final Set<FunctionEntity> forwardingSyntaxImpls = new Set<FunctionEntity>();

  final CommonElements _commonElements;
  final NoSuchMethodResolver _resolver;

  NoSuchMethodRegistryImpl(this._commonElements, this._resolver);

  NoSuchMethodResolver get internalResolverForTesting => _resolver;

  @override
  bool get hasThrowingNoSuchMethod => throwingImpls.isNotEmpty;
  @override
  bool get hasComplexNoSuchMethod => otherImpls.isNotEmpty;

  @override
  void registerNoSuchMethod(FunctionEntity noSuchMethodElement) {
    _uncategorizedImpls.add(noSuchMethodElement);
  }

  @override
  void onQueueEmpty() {
    _uncategorizedImpls.forEach(_categorizeImpl);
    _uncategorizedImpls.clear();
  }

  NsmCategory _categorizeImpl(FunctionEntity element) {
    assert(element.name == Identifiers.noSuchMethod_);
    assert(!element.isAbstract);
    if (defaultImpls.contains(element)) {
      return NsmCategory.DEFAULT;
    }
    if (throwingImpls.contains(element)) {
      return NsmCategory.THROWING;
    }
    if (otherImpls.contains(element)) {
      return NsmCategory.OTHER;
    }
    if (notApplicableImpls.contains(element)) {
      return NsmCategory.NOT_APPLICABLE;
    }
    if (!Selectors.noSuchMethod_.signatureApplies(element)) {
      notApplicableImpls.add(element);
      return NsmCategory.NOT_APPLICABLE;
    }
    if (_commonElements.isDefaultNoSuchMethodImplementation(element)) {
      defaultImpls.add(element);
      return NsmCategory.DEFAULT;
    } else if (_resolver.hasForwardingSyntax(element)) {
      forwardingSyntaxImpls.add(element);
      // If the implementation is 'noSuchMethod(x) => super.noSuchMethod(x);'
      // then it is in the same category as the super call.
      FunctionEntity superCall = _resolver.getSuperNoSuchMethod(element);
      NsmCategory category = _categorizeImpl(superCall);
      switch (category) {
        case NsmCategory.DEFAULT:
          defaultImpls.add(element);
          break;
        case NsmCategory.THROWING:
          throwingImpls.add(element);
          break;
        case NsmCategory.OTHER:
          otherImpls.add(element);
          break;
        case NsmCategory.NOT_APPLICABLE:
          // If the super method is not applicable, the call is redirected to
          // `Object.noSuchMethod`.
          defaultImpls.add(element);
          category = NsmCategory.DEFAULT;
          break;
      }
      return category;
    } else if (_resolver.hasThrowingSyntax(element)) {
      throwingImpls.add(element);
      return NsmCategory.THROWING;
    } else {
      otherImpls.add(element);
      return NsmCategory.OTHER;
    }
  }

  @override
  NoSuchMethodData close() {
    return new NoSuchMethodDataImpl(
        throwingImpls, otherImpls, forwardingSyntaxImpls);
  }
}

/// Data object used during type inference.
///
/// Post inference collected category `D` methods are into subcategories `D1`
/// and `D2`.
abstract class NoSuchMethodData {
  /// Deserializes a [NoSuchMethodData] object from [source].
  factory NoSuchMethodData.readFromDataSource(DataSource source) =
      NoSuchMethodDataImpl.readFromDataSource;

  /// Serializes this [NoSuchMethodData] to [sink].
  void writeToDataSink(DataSink sink);

  /// Returns [true] if the given element is a complex [noSuchMethod]
  /// implementation. An implementation is complex if it falls into
  /// category D, as described above.
  bool isComplex(FunctionEntity element);

  /// Now that type inference is complete, split category D into two
  /// subcategories: D1, those that have no return type, and D2, those
  /// that have a return type.
  void categorizeComplexImplementations(GlobalTypeInferenceResults results);

  /// Emits a diagnostic about methods in categories `B`, `D1` and `D2`.
  void emitDiagnostic(DiagnosticReporter reporter);
}

class NoSuchMethodDataImpl implements NoSuchMethodData {
  /// Tag used for identifying serialized [NoSuchMethodData] objects in a
  /// debugging data stream.
  static const String tag = 'no-such-method-data';

  /// The implementations that fall into category B, described above.
  final Set<FunctionEntity> throwingImpls;

  /// The implementations that fall into category D, described above.
  final Set<FunctionEntity> otherImpls;

  /// The implementations that fall into category D1
  final Set<FunctionEntity> complexNoReturnImpls = new Set<FunctionEntity>();

  /// The implementations that fall into category D2
  final Set<FunctionEntity> complexReturningImpls = new Set<FunctionEntity>();

  final Set<FunctionEntity> forwardingSyntaxImpls;

  NoSuchMethodDataImpl(
      this.throwingImpls, this.otherImpls, this.forwardingSyntaxImpls);

  factory NoSuchMethodDataImpl.readFromDataSource(DataSource source) {
    source.begin(tag);
    Set<FunctionEntity> throwingImpls =
        source.readMembers<FunctionEntity>().toSet();
    Set<FunctionEntity> otherImpls =
        source.readMembers<FunctionEntity>().toSet();
    Set<FunctionEntity> forwardingSyntaxImpls =
        source.readMembers<FunctionEntity>().toSet();
    List<FunctionEntity> complexNoReturnImpls =
        source.readMembers<FunctionEntity>();
    List<FunctionEntity> complexReturningImpls =
        source.readMembers<FunctionEntity>();
    source.end(tag);
    return new NoSuchMethodDataImpl(
        throwingImpls, otherImpls, forwardingSyntaxImpls)
      ..complexNoReturnImpls.addAll(complexNoReturnImpls)
      ..complexReturningImpls.addAll(complexReturningImpls);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeMembers(throwingImpls);
    sink.writeMembers(otherImpls);
    sink.writeMembers(forwardingSyntaxImpls);
    sink.writeMembers(complexNoReturnImpls);
    sink.writeMembers(complexReturningImpls);
    sink.end(tag);
  }

  @override
  void categorizeComplexImplementations(GlobalTypeInferenceResults results) {
    otherImpls.forEach((FunctionEntity element) {
      if (results.resultOfMember(element).throwsAlways) {
        complexNoReturnImpls.add(element);
      } else {
        complexReturningImpls.add(element);
      }
    });
  }

  @override
  void emitDiagnostic(DiagnosticReporter reporter) {
    throwingImpls.forEach((e) {
      if (!forwardingSyntaxImpls.contains(e)) {
        reporter.reportHintMessage(e, MessageKind.DIRECTLY_THROWING_NSM);
      }
    });
    complexNoReturnImpls.forEach((e) {
      if (!forwardingSyntaxImpls.contains(e)) {
        reporter.reportHintMessage(e, MessageKind.COMPLEX_THROWING_NSM);
      }
    });
    complexReturningImpls.forEach((e) {
      if (!forwardingSyntaxImpls.contains(e)) {
        reporter.reportHintMessage(e, MessageKind.COMPLEX_RETURNING_NSM);
      }
    });
  }

  @override
  bool isComplex(FunctionEntity element) {
    assert(element.name == Identifiers.noSuchMethod_);
    return otherImpls.contains(element);
  }
}

enum NsmCategory {
  DEFAULT,
  THROWING,
  NOT_APPLICABLE,
  OTHER,
}

/// Interface for determining the form of a `noSuchMethod` implementation.
abstract class NoSuchMethodResolver {
  /// Computes whether [method] is of the form
  ///
  ///     noSuchMethod(i) => super.noSuchMethod(i);
  ///
  bool hasForwardingSyntax(covariant FunctionEntity method);

  /// Computes whether [method] is of the form
  ///
  ///     noSuchMethod(i) => throw new Error();
  ///
  bool hasThrowingSyntax(covariant FunctionEntity method);

  /// Returns the `noSuchMethod` that [method] overrides.
  FunctionEntity getSuperNoSuchMethod(covariant FunctionEntity method);
}
