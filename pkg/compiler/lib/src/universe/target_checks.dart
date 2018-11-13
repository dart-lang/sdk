// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.target_checks;

/// A summary of the checks required when entering a target method.
///
/// The target checks are used to annotate call sites with the checking required
/// from that call site.
///
/// The target can either perform worst-case checks over all call sites, or can
/// be generated as multiple entry points for different TargetChecks.
///
/// The TargetChecks at a call site can be refined by analysis.  For example,
/// the generic covariant check for writing into a List might not be required
/// when copying values from a List allocated with the same type variable value.
///
/// The TargetChecks at a call site can be used to inform optimizations, for
/// example, only lowering to simpler instructions when generic covariant check
/// is required.
///
/// Unsound modes can be implemented in a scoped manner by using a TargetChecks
/// that has fewer checks than required (or no checks) in the unsound region.
class TargetChecks {
  // Typical of direct static call sites.
  // Typical of static method targets with no tear-offs.
  static final TargetChecks none = const TargetChecks._(false, false, false);

  // Typical of closure calls and dynamic calls.
  static final TargetChecks dynamicChecks =
      const TargetChecks._(true, true, true);

  // Typical of method calls.
  static final TargetChecks covariantChecks =
      const TargetChecks._(false, true, false);

  // TODO(sra): This can be more fine-grained, talking about individual
  // parameters.
  final bool _checkOtherParameters;
  final bool _checkCovariantParameters;
  final bool _checkTypeParameters;
  const TargetChecks._(
    this._checkOtherParameters,
    this._checkCovariantParameters,
    this._checkTypeParameters,
  );

  bool get checkTypeParameters => _checkTypeParameters;
  bool get checkCovariantParameters => _checkCovariantParameters;
  bool get checkAllParameters => _checkOtherParameters;
}
