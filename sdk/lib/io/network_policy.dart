// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/// Whether insecure connections to [host] are allowed.
///
/// [host] must be a [String] or [InternetAddress].
///
/// If any of the domain policies match [host], the matching policy will make
/// the decision. If multiple policies apply, the top matching policy makes the
/// decision. If none of the domain policies match, the embedder default is
/// used.
///
/// Loopback addresses are always allowed.
bool isInsecureConnectionAllowed(dynamic host) {
  String hostString;
  if (host is String) {
    try {
      if ("localhost" == host || InternetAddress(host).isLoopback) return true;
    } on ArgumentError {
      // Assume not loopback.
    }
    hostString = host;
  } else if (host is InternetAddress) {
    if (host.isLoopback) return true;
    hostString = host.host;
  } else {
    throw ArgumentError.value(
        host, "host", "Must be a String or InternetAddress");
  }
  final topMatchedPolicy = _findBestDomainNetworkPolicy(hostString);
  final envOverride = bool.fromEnvironment(
      "dart.library.io.may_insecurely_connect_to_all_domains",
      defaultValue: true);
  return topMatchedPolicy?.allowInsecureConnections ??
      (envOverride && _EmbedderConfig._mayInsecurelyConnectToAllDomains);
}

/// Policy for a specific domain.
///
/// [_DomainNetworkPolicy] can be used to create exceptions to the global
/// network policy.
class _DomainNetworkPolicy {
  /// https://tools.ietf.org/html/rfc1034#:~:text=Name%20space%20specifications
  ///
  /// We specifically do not allow IP addresses.
  static final _domainMatcher = RegExp(
      r"^(?:[a-z\d-]{1,63}\.)+[a-z][a-z\d-]{0,62}$",
      caseSensitive: false);

  /// The domain on which the policy is being set.
  ///
  /// This cannot be a numeric IP address.
  ///
  /// For example: `example.com`.
  final String domain;

  /// Whether to allow insecure socket connections for this domain.
  final bool allowInsecureConnections;

  /// Whether this domain policy covers sub-domains as well.
  ///
  /// If this is true, all subdomains inherit the same policy. For instance,
  /// a policy set on `example.com` would apply to `*.example.com` such as
  /// `subdomain.example.com` or `www.example.com`.
  final bool includesSubDomains;

  /// Creates a new domain exception in the network policy.
  ///
  /// [domain] is the domain on which the policy is being set.
  ///
  /// [includesSubDomains] determines whether the policy applies to
  /// all sub domains. If this is set to true, all subdomains inherit the
  /// same policy. For instance, a policy set on `example.com` would apply to
  /// `*.example.com` such as `subdomain.example.com` or `www.example.com`.
  ///
  /// [allowInsecureConnections] determines whether to allow insecure socket
  /// connections for this [domain].
  _DomainNetworkPolicy(this.domain,
      {this.includesSubDomains = false,
      this.allowInsecureConnections = false}) {
    if (domain.length > 255 || !_domainMatcher.hasMatch(domain)) {
      throw ArgumentError.value(domain, "domain", "Invalid domain name");
    }
  }

  /// Calculates how well the policy matches to a given host string.
  ///
  /// A host matches a [policy] if it ends with its [domain].
  ///
  /// A score is given to such a match depending on the specificity of the
  /// [domain]:
  ///
  /// * A longer domain receives a higher score.
  /// * A domain that does not allow sub domains receives a higher score.
  ///
  /// Returns -1 if the policy does not match.
  int matchScore(String host) {
    final domainLength = domain.length;
    final hostLength = host.length;
    final lengthDelta = hostLength - domainLength;
    if (host.endsWith(domain) &&
        (lengthDelta == 0 ||
            includesSubDomains && host.codeUnitAt(lengthDelta - 1) == 0x2e)) {
      return domainLength * 2 + (includesSubDomains ? 0 : 1);
    }
    return -1;
  }

  /// Checks whether the [policy] to be added conflicts with existing policies.
  ///
  /// Returns [true] if policy is safe to add to existing policy set and [false]
  ///     if policy can safely be ignored.
  ///
  /// Throws [ArgumentError] if a conflict is detected.
  bool checkConflict(List<_DomainNetworkPolicy> existingPolicies) {
    for (final existingPolicy in existingPolicies) {
      if (includesSubDomains == existingPolicy.includesSubDomains &&
          domain == existingPolicy.domain) {
        if (allowInsecureConnections ==
            existingPolicy.allowInsecureConnections) {
          // This is a duplicate policy
          return false;
        }
        throw StateError("Contradiction in the domain security policies: "
            "'$this' contradicts '$existingPolicy'");
      }
    }
    return true;
  }

  /// This is used for encoding information about the policy in user visible
  /// errors.
  @override
  String toString() {
    final subDomainPrefix = includesSubDomains ? '*.' : '';
    final insecureConnectionPermission =
        allowInsecureConnections ? 'Allows' : 'Disallows';
    return "$subDomainPrefix$domain: "
        "$insecureConnectionPermission insecure connections";
  }
}

/// Finds the top [DomainNetworkPolicy] instance that match given a single
/// [domain].
///
/// We order the policies according to how specific they are. The final policy
/// for a given [domain] is determined by the top matching
/// [DomainNetworkPolicy].
///
/// Returns null if there's no matching policy.
_DomainNetworkPolicy? _findBestDomainNetworkPolicy(String domain) {
  var topScore = 0;
  _DomainNetworkPolicy? topPolicy;
  for (final _DomainNetworkPolicy policy in _domainPolicies) {
    final score = policy.matchScore(domain);
    if (score > topScore) {
      topScore = score;
      topPolicy = policy;
    }
  }
  return topPolicy;
}

/// Domain level policies that dart:io is enforcing.
late List<_DomainNetworkPolicy> _domainPolicies =
    _constructDomainPolicies(null);

List<_DomainNetworkPolicy> _constructDomainPolicies(
    String? domainPoliciesString) {
  final domainPolicies = <_DomainNetworkPolicy>[];
  domainPoliciesString ??= String.fromEnvironment(
      "dart.library.io.domain_network_policies",
      defaultValue: "");
  if (domainPoliciesString.isNotEmpty) {
    final List<dynamic> policiesJson = json.decode(domainPoliciesString);
    for (final List<dynamic> policyJson in policiesJson) {
      assert(policyJson.length == 3);
      final policy = _DomainNetworkPolicy(
        policyJson[0],
        includesSubDomains: policyJson[1],
        allowInsecureConnections: policyJson[2],
      );
      if (policy.checkConflict(domainPolicies)) {
        domainPolicies.add(policy);
      }
    }
  }
  return domainPolicies;
}
