# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines accounts used on builders.
"""

accounts = struct(
    ci_builder = "dart-luci-ci-builder@dart-ci.iam.gserviceaccount.com",
    try_builder = "dart-luci-try-builder@dart-ci.iam.gserviceaccount.com",
)
