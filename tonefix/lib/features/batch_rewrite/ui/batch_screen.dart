import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tonefix/core/di/injection_container.dart';
import 'package:tonefix/core/services/tone_engine.dart';
import 'package:tonefix/features/batch_rewrite/bloc/batch_bloc.dart';
import 'package:tonefix/shared/models/tone_models.dart';

class BatchRewriteScreen extends StatelessWidget {
  const BatchRewriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BatchBloc>(),
      child: const _BatchView(),
    );
  }
}

class _BatchView extends StatefulWidget {
  const _BatchView();

  @override
  State<_BatchView> createState() => _BatchViewState();
}

class _BatchViewState extends State<_BatchView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Batch Rewrite'),
        centerTitle: true,
        actions: [
          BlocBuilder<BatchBloc, BatchState>(
            builder: (context, state) {
              if (state.phase == BatchPhase.done) {
                return IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    _controller.clear();
                    context.read<BatchBloc>().add(BatchReset());
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<BatchBloc, BatchState>(
        builder: (context, state) {
          if (state.phase == BatchPhase.done) {
            return _ResultsView(state: state);
          }
          return _InputView(
            controller: _controller,
            state: state,
            onSubmit: (tone) => context.read<BatchBloc>().add(
                  BatchStartRequested(
                    rawInput: _controller.text,
                    tone: tone,
                  ),
                ),
            onToneChanged: (tone) =>
                context.read<BatchBloc>().add(BatchToneSelected(tone)),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input View
// ─────────────────────────────────────────────────────────────────────────────

class _InputView extends StatelessWidget {
  const _InputView({
    required this.controller,
    required this.state,
    required this.onSubmit,
    required this.onToneChanged,
  });

  final TextEditingController controller;
  final BatchState state;
  final void Function(ToneType) onSubmit;
  final void Function(ToneType) onToneChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunning = state.isRunning;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hint
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Paste multiple messages separated by  ---  (triple dash)',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Text input
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isRunning,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Message 1 text here\n---\nMessage 2 text here\n---\nMessage 3 text here',
                hintStyle: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.3)),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tone selector
          Text('Select Tone',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.1,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              )),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ToneType.values.map((tone) {
                final isSelected = tone == state.selectedTone;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: isRunning ? null : () => onToneChanged(tone),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? tone.color : theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? tone.color : theme.dividerColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tone.emoji),
                          const SizedBox(width: 6),
                          Text(
                            tone.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : null,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Progress indicator (while running)
          if (isRunning) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rewriting message ${state.currentIndex} of ${state.total}…',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${(state.progress * 100).round()}%',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: state.progress,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],

          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(state.error!,
                  style: TextStyle(
                      color: theme.colorScheme.error, fontSize: 13)),
            ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isRunning ? null : () => onSubmit(state.selectedTone),
              icon: isRunning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_fix_high_rounded),
              label: Text(isRunning ? 'Processing…' : 'Rewrite All Messages'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Results View
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.state});
  final BatchState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = state.completedItems;
    final successCount = items.where((i) => i.isSuccess).length;

    return Column(
      children: [
        // Summary bar
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '$successCount/${items.length} messages rewritten',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _exportAll(context, items),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Export'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Result cards
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _BatchResultCard(item: items[i], index: i),
          ),
        ),
      ],
    );
  }

  void _exportAll(BuildContext context, List<BatchRewriteProgress> items) {
    final buffer = StringBuffer();
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      buffer.writeln('=== Message ${i + 1} ===');
      buffer.writeln('[Original]');
      buffer.writeln(item.original);
      buffer.writeln();
      if (item.isSuccess) {
        buffer.writeln('[Rewritten]');
        buffer.writeln(item.result!.rewrittenText);
      } else {
        buffer.writeln('[Error] ${item.error}');
      }
      buffer.writeln();
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All results copied to clipboard!')),
    );
  }
}

class _BatchResultCard extends StatefulWidget {
  const _BatchResultCard({required this.item, required this.index});
  final BatchRewriteProgress item;
  final int index;

  @override
  State<_BatchResultCard> createState() => _BatchResultCardState();
}

class _BatchResultCardState extends State<_BatchResultCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final tone = item.result?.tone;

    return Container(
      decoration: BoxDecoration(
        color: item.isSuccess
            ? tone?.color.withOpacity(0.05) ?? theme.cardColor
            : theme.colorScheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isSuccess
              ? tone?.color.withOpacity(0.2) ?? theme.dividerColor
              : theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.isSuccess
                          ? tone?.color.withOpacity(0.15) ?? Colors.grey.shade200
                          : theme.colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.isSuccess ? '#${widget.index + 1}' : 'Error',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: item.isSuccess ? tone?.color : theme.colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.isSuccess
                          ? (item.result!.rewrittenText.length > 80
                              ? '${item.result!.rewrittenText.substring(0, 80)}…'
                              : item.result!.rewrittenText)
                          : item.error ?? 'Failed',
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (item.isSuccess)
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: item.result!.rewrittenText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied!')),
                        );
                      },
                    ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
            ),
          ),

          // Expanded detail
          if (_expanded && item.isSuccess) ...[
            Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Original',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                  const SizedBox(height: 6),
                  Text(item.original, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Text('Rewritten',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                  const SizedBox(height: 6),
                  Text(item.result!.rewrittenText,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
