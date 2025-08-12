import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final VoidCallback onRestart;
  final VoidCallback onToggleTheme;
  final VoidCallback onUndo;
  final VoidCallback onHelp;
  final Color primary;
  final int score;

  // --- NOVO: caos opcional ---
  final String? chaosLabel; // ex.: "Controles Invertidos"
  final int? chaosMovesLeft; // ex.: 7 (jogadas restantes)

  const TopBar({
    super.key,
    required this.onRestart,
    required this.onToggleTheme,
    required this.onUndo,
    required this.onHelp,
    required this.primary,
    required this.score,
    this.chaosLabel,
    this.chaosMovesLeft,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Restart com largura flexível
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 140, maxWidth: 260),
          child: FilledButton(onPressed: onRestart, style: FilledButton.styleFrom(backgroundColor: primary), child: const Text('Restart')),
        ),

        // Score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Text('Score: $score', style: textStyle),
        ),

        // Chip de Caos (só aparece quando ativo)
        if (chaosLabel != null && chaosMovesLeft != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text('Caos: $chaosLabel ($chaosMovesLeft)', style: textStyle?.copyWith(fontWeight: FontWeight.w600)),
          ),

        // Ações compactas
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(onPressed: onUndo, icon: const Icon(Icons.undo), tooltip: 'Voltar jogada'),
            const SizedBox(width: 4),
            IconButton.filledTonal(onPressed: onToggleTheme, icon: const Icon(Icons.palette), tooltip: 'Alternar tema'),
            const SizedBox(width: 4),
            IconButton.filledTonal(onPressed: onHelp, icon: const Icon(Icons.help_outline), tooltip: 'Como funciona'),
          ],
        ),
      ],
    );
  }
}
