// PLACEHOLDER RULES
//
// Everything game-specific lives in lib/game/. The networking, storage and
// screens only depend on CharacterSheet's JSON shape, so this file can be
// rewritten with the real Ordem Paranormal EZ rules without touching them.

/// A resource with a current and a maximum value (life, effort, sanity...).
class Resource {
  const Resource({required this.current, required this.max});

  final int current;
  final int max;

  Resource copyWith({int? current, int? max}) {
    final newMax = max ?? this.max;
    final newCurrent = (current ?? this.current).clamp(0, newMax);
    return Resource(current: newCurrent, max: newMax);
  }

  Map<String, dynamic> toJson() => {'current': current, 'max': max};

  factory Resource.fromJson(Map<String, dynamic> json) => Resource(
        current: (json['current'] as num).toInt(),
        max: (json['max'] as num).toInt(),
      );
}

/// Placeholder definition of the game system: which attributes and resources
/// a sheet has, and their starting values.
class GameRules {
  static const attributes = ['AGI', 'FOR', 'INT', 'PRE', 'VIG'];
  static const resources = ['PV', 'PE', 'SAN'];

  static const resourceLabels = {
    'PV': 'Vida',
    'PE': 'Esforço',
    'SAN': 'Sanidade',
  };

  static CharacterSheet newSheet({required String id, required String name}) {
    return CharacterSheet(
      id: id,
      name: name,
      attributes: {for (final a in attributes) a: 1},
      resources: {for (final r in resources) r: const Resource(current: 10, max: 10)},
      notes: '',
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// One player's character. Immutable: every change produces a new sheet with
/// a fresh [updatedAt], which the host uses to decide which copy is newer.
class CharacterSheet {
  const CharacterSheet({
    required this.id,
    required this.name,
    required this.attributes,
    required this.resources,
    required this.notes,
    required this.updatedAt,
  });

  /// Same as the owning player's id.
  final String id;
  final String name;
  final Map<String, int> attributes;
  final Map<String, Resource> resources;
  final String notes;

  /// Milliseconds since epoch of the last change.
  final int updatedAt;

  CharacterSheet copyWith({
    String? name,
    Map<String, int>? attributes,
    Map<String, Resource>? resources,
    String? notes,
  }) {
    return CharacterSheet(
      id: id,
      name: name ?? this.name,
      attributes: attributes ?? this.attributes,
      resources: resources ?? this.resources,
      notes: notes ?? this.notes,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  CharacterSheet withAttribute(String key, int value) =>
      copyWith(attributes: {...attributes, key: value});

  CharacterSheet withResource(String key, Resource value) =>
      copyWith(resources: {...resources, key: value});

  /// Adds [delta] to a resource's current value, clamped to 0..max.
  CharacterSheet adjustResource(String key, int delta) {
    final r = resources[key];
    if (r == null) return this;
    return withResource(key, r.copyWith(current: r.current + delta));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'attributes': attributes,
        'resources': resources.map((k, v) => MapEntry(k, v.toJson())),
        'notes': notes,
        'updatedAt': updatedAt,
      };

  factory CharacterSheet.fromJson(Map<String, dynamic> json) => CharacterSheet(
        id: json['id'] as String,
        name: json['name'] as String,
        attributes: (json['attributes'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        resources: (json['resources'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, Resource.fromJson(v as Map<String, dynamic>))),
        notes: json['notes'] as String? ?? '',
        updatedAt: (json['updatedAt'] as num).toInt(),
      );
}
