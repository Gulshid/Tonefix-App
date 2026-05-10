import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tonefix/core/di/injection_container.dart';
import 'package:tonefix/features/voice_to_tone/bloc/voice_bloc.dart';
import 'package:tonefix/routes/app_router.dart';
import 'package:tonefix/shared/models/tone_models.dart';

class VoiceToToneScreen extends StatelessWidget {
  const VoiceToToneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VoiceBloc>()..add(VoiceInitRequested()),
      child: const _VoiceView(),
    );
  }
}

class _VoiceView extends StatefulWidget {
  const _VoiceView();

  @override
  State<_VoiceView> createState() => _VoiceViewState();
}

class _VoiceViewState extends State<_VoiceView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  ToneType _selectedTone = ToneType.professional;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Voice to Tone'),
        centerTitle: true,
        actions: [
          BlocBuilder<VoiceBloc, VoiceState>(
            builder: (context, state) {
              if (state.phase == VoicePhase.done || state.phase == VoicePhase.error) {
                return IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => context.read<VoiceBloc>().add(VoiceReset()),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<VoiceBloc, VoiceState>(
        listener: (context, state) {
          if (state.phase == VoicePhase.listening) {
            _pulseController.repeat(reverse: true);
          } else {
            _pulseController.stop();
            _pulseController.value = 0;
          }
          if (state.phase == VoicePhase.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error ?? 'An error occurred'),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return switch (state.phase) {
            VoicePhase.unavailable => _UnavailableBody(),
            VoicePhase.done => _ResultBody(
                state: state,
                onGoToRewrite: () => context.push(
                  AppRoutes.rewrite,
                  extra: state.result,
                ),
              ),
            _ => _MainBody(
                state: state,
                pulseController: _pulseController,
                selectedTone: _selectedTone,
                onToneChanged: (t) => setState(() => _selectedTone = t),
                onMicTap: () => _handleMicTap(context, state),
                onRewrite: () => context.read<VoiceBloc>().add(
                      VoiceRewriteRequested(
                        text: state.transcript,
                        tone: _selectedTone,
                      ),
                    ),
              ),
          };
        },
      ),
    );
  }

  void _handleMicTap(BuildContext context, VoiceState state) {
    final bloc = context.read<VoiceBloc>();
    if (state.isListening) {
      bloc.add(VoiceStopListening());
    } else {
      bloc.add(VoiceStartListening());
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Body
// ─────────────────────────────────────────────────────────────────────────────

class _MainBody extends StatelessWidget {
  const _MainBody({
    required this.state,
    required this.pulseController,
    required this.selectedTone,
    required this.onToneChanged,
    required this.onMicTap,
    required this.onRewrite,
  });

  final VoiceState state;
  final AnimationController pulseController;
  final ToneType selectedTone;
  final void Function(ToneType) onToneChanged;
  final VoidCallback onMicTap;
  final VoidCallback onRewrite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isListening = state.isListening;
    final isRewriting = state.phase == VoicePhase.rewriting;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Instructions
          Text(
            isListening
                ? 'Listening… speak clearly'
                : state.phase == VoicePhase.transcribed
                    ? 'Transcription complete'
                    : 'Tap the mic and start speaking',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Mic button
          AnimatedBuilder(
            animation: pulseController,
            builder: (_, child) {
              final scale = isListening ? 1.0 + pulseController.value * 0.15 : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: GestureDetector(
              onTap: onMicTap,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isListening
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (isListening
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary)
                          .withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Transcript box
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: state.transcript.isNotEmpty
                  ? SingleChildScrollView(
                      child: Text(
                        state.transcript,
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
                  : Center(
                      child: Text(
                        'Your transcription will appear here…',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // Tone selector
          if (state.phase == VoicePhase.transcribed || state.phase == VoicePhase.rewriting) ...[
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ToneType.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tone = ToneType.values[index];
                  final isSelected = tone == selectedTone;
                  return GestureDetector(
                    onTap: () => onToneChanged(tone),
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
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isRewriting ? null : onRewrite,
                icon: isRewriting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_fix_high_rounded),
                label: Text(isRewriting ? 'Rewriting…' : 'Rewrite in ${selectedTone.label} Tone'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result Body
// ─────────────────────────────────────────────────────────────────────────────

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.state, required this.onGoToRewrite});
  final VoiceState state;
  final VoidCallback onGoToRewrite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = state.result!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Original (voice)', style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            letterSpacing: 1.2,
          )),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(result.originalText, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Rewritten (${result.tone.emoji} ${result.tone.label})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    letterSpacing: 1.2,
                  )),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result.rewrittenText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: result.tone.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: result.tone.color.withOpacity(0.3)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  result.rewrittenText,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onGoToRewrite,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Open in Rewrite Screen'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unavailable Body
// ─────────────────────────────────────────────────────────────────────────────

class _UnavailableBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_off_rounded,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 24),
            Text('Microphone unavailable',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'Speech recognition is not available on this device '
              'or microphone permission was denied. '
              'Please enable microphone access in Settings.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
