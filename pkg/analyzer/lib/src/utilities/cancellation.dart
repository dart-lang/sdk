// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CancelableToken extends CancellationToken {
  bool _isCancelled = false;
  int? _cancellationCode;
  String? _cancellationReason;

  /// An optional code for why this request was cancelled.
  int? get cancellationCode => _cancellationCode;

  /// An description for why this request was cancelled.
  String? get cancellationReason => _cancellationReason;

  @override
  bool get isCancellationRequested => _isCancelled;

  void cancel({int? code, String? reason}) {
    _isCancelled = true;
    _cancellationCode = code;
    _cancellationReason = reason;
  }
}

/// A token used to signal cancellation of an operation. This allows computation
/// to be skipped when a caller is no longer interested in the result, for example
/// when a $/cancel request is received for an in-progress request.
abstract class CancellationToken {
  bool get isCancellationRequested;
}

/// A [CancellationToken] that cannot be cancelled.
class NotCancelableToken extends CancellationToken {
  @override
  bool get isCancellationRequested => false;
}

/// A cancellable wrapper over another cancellation token.
///
/// This token will be considered cancelled if either it is itself cancelled,
/// or if [_child] is cancelled.
///
/// Cancelling this token will also cancel [_child] if it is a cancelable
/// token.
class _WrappedCancelableToken extends CancelableToken {
  final CancellationToken _child;

  _WrappedCancelableToken(this._child);

  @override
  bool get isCancellationRequested =>
      super.isCancellationRequested || _child.isCancellationRequested;

  @override
  void cancel({int? code, String? reason}) {
    super.cancel(code: code, reason: reason);
    var child = _child;
    if (child is CancelableToken) {
      child.cancel(code: code, reason: reason);
    }
  }
}

extension CancellationTokenExtension on CancellationToken {
  /// Wraps this token to make it cancelable if it is not already.
  CancelableToken asCancelable() {
    var token = this;
    return token is CancelableToken ? token : _WrappedCancelableToken(token);
  }
}
