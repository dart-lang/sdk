# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines priorities used by for swarming tasks. The higher the number, the lower
the priority.
"""

priority = struct(
    low = 70,  # Used for "FYI" post-submit builds.
    normal = 50,  # Used for post-submit builds.
    high = 30,  # Used for try-jobs.
    highest = 25,  # Used for shards in the recipes, only here for completeness.
)
