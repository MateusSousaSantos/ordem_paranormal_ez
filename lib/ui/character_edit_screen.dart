import 'package:flutter/material.dart';

import '../game/character_library.dart';
import '../game/character_sheet.dart';
import 'widgets/die_stepper.dart';

/// Create or edit a saved character.
class CharacterEditScreen extends StatefulWidget {
  const CharacterEditScreen({super.key, required this.library, required this.initial});

  final CharacterLibrary library;
  final CharacterSheet initial;

  @override
  State<CharacterEditScreen> createState() => _CharacterEditScreenState();
}

class _CharacterEditScreenState extends State<CharacterEditScreen> {
  final _form = GlobalKey<FormState>();
  late CharacterSheet _sheet = widget.initial;
  late final _name = TextEditingController(text: _sheet.name);
  late final _vocacao = TextEditingController(text: _sheet.vocacao);
  late final _nivel = TextEditingController(text: '${_sheet.nivel}');
  late final _pv = TextEditingController(text: '${_sheet.pv.max}');
  late final _pd = TextEditingController(text: '${_sheet.pd.max}');

  bool get _isNew => widget.library.byId(widget.initial.id) == null;

  @override
  void dispose() {
    for (final c in [_name, _vocacao, _nivel, _pv, _pd]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final pvMax = int.parse(_pv.text);
    final pdMax = int.parse(_pd.text);
    // A new character starts full; an edited one keeps its current values.
    final sheet = _sheet.copyWith(
      name: _name.text.trim(),
      vocacao: _vocacao.text.trim(),
      nivel: int.parse(_nivel.text),
      pv: _isNew ? Resource(current: pvMax, max: pvMax) : _sheet.pv.copyWith(max: pvMax),
      pd: _isNew ? Resource(current: pdMax, max: pdMax) : _sheet.pd.copyWith(max: pdMax),
    );
    await widget.library.save(sheet);
    if (mounted) Navigator.pop(context, sheet);
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null;

  String? _number(String? v) {
    final n = int.tryParse(v ?? '');
    return (n == null || n < 0) ? 'Número inválido' : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Novo personagem' : 'Editar personagem'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Salvar')),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome'),
              textCapitalization: TextCapitalization.words,
              validator: _required,
            ),
            TextFormField(
              controller: _vocacao,
              decoration: const InputDecoration(labelText: 'Vocação'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nivel,
                    decoration: const InputDecoration(labelText: 'Nível'),
                    keyboardType: TextInputType.number,
                    validator: _number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _pv,
                    decoration: const InputDecoration(labelText: 'PV máximo'),
                    keyboardType: TextInputType.number,
                    validator: _number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _pd,
                    decoration: const InputDecoration(labelText: 'PD máximo'),
                    keyboardType: TextInputType.number,
                    validator: _number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Perfil psicológico', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<PerfilPsicologico>(
              segments: [
                for (final p in PerfilPsicologico.values)
                  ButtonSegment(value: p, label: Text(p.label)),
              ],
              selected: {_sheet.perfil},
              onSelectionChanged: (s) => setState(() => _sheet = _sheet.copyWith(perfil: s.first)),
            ),
            const SizedBox(height: 24),
            Text('Atributos', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in GameRules.atributos)
                  DieStepper(
                    label: GameRules.atributoLabels[key]!,
                    die: _sheet.atributos[key]!,
                    onChanged: (d) => setState(() => _sheet = _sheet.withAtributo(key, d)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Perícias', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in GameRules.pericias)
                  DieStepper(
                    label: key,
                    die: _sheet.pericias[key]!,
                    onChanged: (d) => setState(() => _sheet = _sheet.withPericia(key, d)),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(onPressed: _save, child: const Text('Salvar personagem')),
          ],
        ),
      ),
    );
  }
}
