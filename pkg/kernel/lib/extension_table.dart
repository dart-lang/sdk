// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

/// Lookup table that provides access to the descriptor for extension and
/// extension type members.
class ExtensionTable {
  final Map<Library, _LibraryInfo> _infoMap = {};

  /// Returns the [ExtensionMemberInfo] for [member].
  ///
  /// [member] must be marked as an extension member.
  ExtensionMemberInfo getExtensionMemberInfo(Member member) {
    if (!member.isExtensionMember) {
      throw new ArgumentError("Member $member must be an extension member.");
    }
    _LibraryInfo info = _getLibraryInfo(member.enclosingLibrary);
    return info.getExtensionMemberInfo(member);
  }

  /// Returns the [ExtensionTypeMemberInfo] for [member].
  ///
  /// [member] must be marked as an extension type member.
  ExtensionTypeMemberInfo getExtensionTypeMemberInfo(Member member) {
    if (!member.isExtensionTypeMember) {
      throw new ArgumentError("Member $member must be an extension member.");
    }
    _LibraryInfo info = _getLibraryInfo(member.enclosingLibrary);
    return info.getExtensionTypeMemberInfo(member);
  }

  _LibraryInfo _getLibraryInfo(Library library) {
    return _infoMap[library] ??= new _LibraryInfo(library);
  }
}

/// Information about an extension member lowered as a top level member.
class ExtensionMemberInfo {
  /// The extension to which the member belongs.
  final Extension extension;

  /// The lowered top level member.
  final Member member;

  /// The [ExtensionMemberDescriptor] for the lowered [member].
  final ExtensionMemberDescriptor descriptor;

  ExtensionMemberInfo(this.extension, this.member, this.descriptor);
}

/// Information about an extension type member lowered as a top level member.
class ExtensionTypeMemberInfo {
  /// The extension type declaration to which the member belongs.
  final ExtensionTypeDeclaration extensionTypeDeclaration;

  /// The lowered top level member.
  final Member member;

  /// The [ExtensionMemberDescriptor] for the lowered [member].
  final ExtensionTypeMemberDescriptor descriptor;

  ExtensionTypeMemberInfo(
      this.extensionTypeDeclaration, this.member, this.descriptor);
}

class _LibraryInfo {
  final Library _library;
  late final _ExtensionTable _extensionTable = new _ExtensionTable(_library);
  late final _ExtensionTypeTable _extensionTypeTable =
      new _ExtensionTypeTable(_library);

  _LibraryInfo(this._library);

  ExtensionMemberInfo getExtensionMemberInfo(Member member) {
    return _extensionTable[member];
  }

  ExtensionTypeMemberInfo getExtensionTypeMemberInfo(Member member) {
    return _extensionTypeTable[member];
  }
}

class _ExtensionTable {
  final Map<Member, ExtensionMemberInfo> _map = {};

  _ExtensionTable(Library library) {
    for (Extension extension in library.extensions) {
      for (ExtensionMemberDescriptor descriptor
          in extension.memberDescriptors) {
        Member? member = descriptor.memberReference?.asMember;
        if (member != null) {
          _map[member] = new ExtensionMemberInfo(extension, member, descriptor);
        }
        Member? tearOff = descriptor.tearOffReference?.asMember;
        if (tearOff != null) {
          _map[tearOff] =
              new ExtensionMemberInfo(extension, tearOff, descriptor);
        }
      }
    }
  }

  ExtensionMemberInfo operator [](Member member) {
    ExtensionMemberInfo? info = _map[member];
    assert(info != null, "No info found for $member in ${_map.keys}");
    return info!;
  }
}

class _ExtensionTypeTable {
  final Map<Member, ExtensionTypeMemberInfo> _map = {};

  _ExtensionTypeTable(Library library) {
    for (ExtensionTypeDeclaration extensionTypeDeclaration
        in library.extensionTypeDeclarations) {
      for (ExtensionTypeMemberDescriptor descriptor
          in extensionTypeDeclaration.memberDescriptors) {
        Member? member = descriptor.memberReference?.asMember;
        if (member != null) {
          _map[member] = new ExtensionTypeMemberInfo(
              extensionTypeDeclaration, member, descriptor);
        }
        Member? tearOff = descriptor.tearOffReference?.asMember;
        if (tearOff != null) {
          _map[tearOff] = new ExtensionTypeMemberInfo(
              extensionTypeDeclaration, tearOff, descriptor);
        }
      }
    }
  }

  ExtensionTypeMemberInfo operator [](Member member) {
    ExtensionTypeMemberInfo? info = _map[member];
    assert(info != null, "No info found for $member in ${_map.keys}");
    return info!;
  }
}
