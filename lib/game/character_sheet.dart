// OP.EZ CHARACTER RULES
//
// Everything game-specific lives in lib/game/. The networking, storage and
// screens only depend on CharacterSheet's JSON shape.

/// Dice used for attributes and perícias, from weakest to strongest.
enum Die {
  d4(4),
  d6(6),
  d8(8),
  d10(10),
  d12(12),
  d20(20);

  const Die(this.sides);
  final int sides;

  String get label => 'd$sides';

  Die? get next => index + 1 < values.length ? values[index + 1] : null;
  Die? get previous => index > 0 ? values[index - 1] : null;
}

enum PerfilPsicologico {
  vigilante('Vigilante'),
  executor('Executor'),
  analista('Analista');

  const PerfilPsicologico(this.label);
  final String label;
}

/// A value with a current and a maximum (PV, PD).
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

class GameRules {
  /// The three core attributes.
  static const atributos = ['fisico', 'mente', 'emocao'];
  static const atributoLabels = {
    'fisico': 'Físico',
    'mente': 'Mente',
    'emocao': 'Emoção',
  };

  /// The 20 perícias. Names are stored in saved sheets, so renaming one
  /// resets it to d4 on existing characters.
  static const pericias = [
    'Acrobacia',
    'Animais',
    'Aptidão',
    'Atletismo',
    'Crime',
    'Disciplina',
    'Enganação',
    'Furtividade',
    'Inspecionar',
    'Intimidar',
    'Intuição',
    'Luta',
    'Medicina',
    'Ocultismo',
    'Ofício',
    'Percepção',
    'Persuasão',
    'Pontaria',
    'Sobrevivência',
    'Vigor',
  ];

  static CharacterSheet newSheet({required String id, String name = ''}) {
    return CharacterSheet(
      id: id,
      name: name,
      nivel: 1,
      vocacao: '',
      perfil: PerfilPsicologico.vigilante,
      atributos: {for (final a in atributos) a: Die.d4},
      pericias: {for (final p in pericias) p: Die.d4},
      pv: const Resource(current: 10, max: 10),
      pd: const Resource(current: 10, max: 10),
      notes: '',
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// One player character. Immutable: every change produces a new sheet with a
/// fresh [updatedAt], which the host uses to decide which copy is newer.
class CharacterSheet {
  const CharacterSheet({
    required this.id,
    required this.name,
    required this.nivel,
    required this.vocacao,
    required this.perfil,
    required this.atributos,
    required this.pericias,
    required this.pv,
    required this.pd,
    required this.notes,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int nivel;
  final String vocacao;
  final PerfilPsicologico perfil;

  /// Físico, Mente, Emoção (keys from [GameRules.atributos]).
  final Map<String, Die> atributos;
  final Map<String, Die> pericias;
  final Resource pv;
  final Resource pd;
  final String notes;

  /// Milliseconds since epoch of the last change.
  final int updatedAt;

  CharacterSheet copyWith({
    String? name,
    int? nivel,
    String? vocacao,
    PerfilPsicologico? perfil,
    Map<String, Die>? atributos,
    Map<String, Die>? pericias,
    Resource? pv,
    Resource? pd,
    String? notes,
  }) {
    return CharacterSheet(
      id: id,
      name: name ?? this.name,
      nivel: nivel ?? this.nivel,
      vocacao: vocacao ?? this.vocacao,
      perfil: perfil ?? this.perfil,
      atributos: atributos ?? this.atributos,
      pericias: pericias ?? this.pericias,
      pv: pv ?? this.pv,
      pd: pd ?? this.pd,
      notes: notes ?? this.notes,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  CharacterSheet withAtributo(String key, Die die) => copyWith(atributos: {...atributos, key: die});
  CharacterSheet withPericia(String key, Die die) => copyWith(pericias: {...pericias, key: die});

  /// Adds [delta] to current PV, clamped to 0..max.
  CharacterSheet adjustPv(int delta) => copyWith(pv: pv.copyWith(current: pv.current + delta));

  /// Adds [delta] to current PD, clamped to 0..max.
  CharacterSheet adjustPd(int delta) => copyWith(pd: pd.copyWith(current: pd.current + delta));

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nivel': nivel,
        'vocacao': vocacao,
        'perfil': perfil.name,
        'atributos': atributos.map((k, v) => MapEntry(k, v.name)),
        'pericias': pericias.map((k, v) => MapEntry(k, v.name)),
        'pv': pv.toJson(),
        'pd': pd.toJson(),
        'notes': notes,
        'updatedAt': updatedAt,
      };

  factory CharacterSheet.fromJson(Map<String, dynamic> json) {
    Map<String, Die> dice(Object? raw, List<String> keys) {
      final m = raw as Map? ?? const {};
      // Unknown or missing keys fall back to d4, so renaming the perícia
      // list doesn't break sheets saved earlier.
      return {
        for (final k in keys) k: Die.values.asNameMap()[m[k]] ?? Die.d4,
      };
    }

    return CharacterSheet(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      nivel: (json['nivel'] as num?)?.toInt() ?? 1,
      vocacao: json['vocacao'] as String? ?? '',
      perfil: PerfilPsicologico.values.asNameMap()[json['perfil']] ?? PerfilPsicologico.vigilante,
      atributos: dice(json['atributos'], GameRules.atributos),
      pericias: dice(json['pericias'], GameRules.pericias),
      pv: json['pv'] == null
          ? const Resource(current: 10, max: 10)
          : Resource.fromJson(json['pv'] as Map<String, dynamic>),
      pd: json['pd'] == null
          ? const Resource(current: 10, max: 10)
          : Resource.fromJson(json['pd'] as Map<String, dynamic>),
      notes: json['notes'] as String? ?? '',
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }
}
