// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:test/test.dart';

/// A [Matcher] that check that the given [Response] has an expected identifier
/// and no error.
Matcher isResponseSuccess(String id) => _IsResponseSuccess(id);

/// A [Matcher] that check that there are no `error` in a given [Response].
class _IsResponseSuccess extends Matcher {
  final String _id;

  _IsResponseSuccess(this._id);

  @override
  Description describe(Description description) {
    return description
        .addDescriptionOf('response with identifier "$_id" and without error');
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    Response response = item as Response;
    if (response == null) {
      mismatchDescription.add('is null response');
    } else {
      var id = response.id;
      var error = response.error;
      mismatchDescription.add('has identifier "$id"');
      if (error != null) {
        mismatchDescription.add(' and has error $error');
      }
    }
    return mismatchDescription;
  }

  @override
  bool matches(item, Map matchState) {
    Response response = item as Response;
    return response != null && response.id == _id && response.error == null;
  }
}
