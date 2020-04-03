// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/// A library containing different type of vector operations for use in games,
/// simulations, or rendering.
///
/// The library contains Vector classes ([Vector2], [Vector3] and [Vector4]),
/// Matrices classes ([Matrix2], [Matrix3] and [Matrix4]) and collision
/// detection related classes ([Aabb2], [Aabb3], [Frustum], [Obb3], [Plane],
/// [Quad], [Ray], [Sphere] and [Triangle]).
///
/// In addition some utilities are available as color operations (See [Colors]
/// class), noise generators ([SimplexNoise]) and common OpenGL operations
/// (like [makeViewMatrix], [makePerspectiveMatrix], or [pickRay]).
///
/// There is also a [vector_math_64_64] library available that uses double
/// precision (64-bit) instead of single precision (32-bit) floating point
/// numbers for storage.
library vector_math_64;

part 'matrix4.dart';
