import 'package:flutter/material.dart';

class HowItWorksSheet extends StatelessWidget {
  const HowItWorksSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Como funciona', style: text.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Deslize para mover os tiles. Quando dois tiles de MESMO número se encontram, '
              'eles se fundem e viram a soma.\nEx.: 2 + 2 = 4, 4 + 4 = 8, 8 + 8 = 16...',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('Exemplos', style: text.titleMedium),
            const SizedBox(height: 8),
            const _ExampleRow(examples: ['2 + 2 = 4', '4 + 4 = 8', '8 + 8 = 16']),
            const SizedBox(height: 12),
            Text('Não funde', style: text.titleMedium),
            const SizedBox(height: 8),
            const _ExampleRow(examples: ['2 + 4 ✗', '4 + 8 ✗', '8 + 16 ✗']),
            const SizedBox(height: 16),

            // ---- Seção do CAOS ----
            Text('Modo Caos', style: text.titleLarge),
            const SizedBox(height: 8),
            Text(
              'A cada 10 jogadas válidas, um efeito de Caos é ativado por um tempo limitado '
              '(normalmente 10 jogadas). O efeito atual aparece na barra superior como "Caos".',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 8),
            const _InfoTile(title: 'Duplo Spawn', body: 'Após cada jogada válida, nascem dois tiles em vez de um.'),
            const SizedBox(height: 8),
            const _InfoTile(
              title: 'Controles Invertidos',
              body: 'As direções são espelhadas: cima vira baixo, esquerda vira direita (e vice‑versa).',
            ),
            const SizedBox(height: 8),
            const _InfoTile(title: 'Embaralhar', body: 'O tabuleiro é embaralhado imediatamente quando o efeito ativa.'),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Text('Pontuação: cada fusão soma o valor do tile resultante ao seu Score.', style: text.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final List<String> examples;
  const _ExampleRow({required this.examples});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          examples
              .map(
                (e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Text(e),
                ),
              )
              .toList(),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String body;
  const _InfoTile({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(body, style: text.bodySmall),
        ],
      ),
    );
  }
}
