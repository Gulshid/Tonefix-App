import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tonefix/core/di/injection_container.dart';
import 'package:tonefix/features/analytics/bloc/analytics_bloc.dart';
import 'package:tonefix/shared/models/tone_models.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AnalyticsBloc>()..add(AnalyticsLoadRequested()),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tone Analytics'),
        centerTitle: true,
        actions: [
          BlocBuilder<AnalyticsBloc, AnalyticsState>(
            builder: (context, state) {
              if (state is! AnalyticsLoaded) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset analytics',
                onPressed: () => _confirmReset(context),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsLoading || state is AnalyticsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AnalyticsError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is AnalyticsLoaded) {
            return _LoadedBody(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Analytics'),
        content: const Text('This will clear all usage data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AnalyticsBloc>().add(AnalyticsResetRequested());
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state});
  final AnalyticsLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = state.totalRewrites;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary cards ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Rewrites',
                  value: '$total',
                  icon: Icons.auto_fix_high_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Favourite Tone',
                  value: state.mostUsedTone != null
                      ? '${state.mostUsedTone!.emoji} ${state.mostUsedTone!.label}'
                      : '—',
                  icon: Icons.star_rounded,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Weekly bar chart ───────────────────────────────────────
          Text('This Week',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Daily rewrite activity',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 16),
          _WeeklyBarChart(dailyUsage: state.dailyUsage),
          const SizedBox(height: 28),

          // ── Tone breakdown ─────────────────────────────────────────
          Text('Tone Breakdown',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Which tones you use most',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 16),

          if (total == 0)
            _EmptyState()
          else ...[
            _ToneDonutChart(toneCounts: state.toneCounts, total: total),
            const SizedBox(height: 20),
            _ToneBreakdownList(toneCounts: state.toneCounts, total: total),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weekly Bar Chart
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.dailyUsage});
  final Map<String, int> dailyUsage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = dailyUsage.entries.toList();
    final maxY = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b).toDouble();

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 5 : (maxY * 1.3).ceilToDouble(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) return const SizedBox();
                  final dateKey = entries[idx].key;
                  final parts = dateKey.split('-');
                  final label = parts.length == 3 ? '${parts[2]}/${parts[1]}' : dateKey;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.dividerColor.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(entries.length, (i) {
            final count = entries[i].value.toDouble();
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: count == 0 ? 0.2 : count,
                  color: theme.colorScheme.primary,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY == 0 ? 5 : (maxY * 1.3).ceilToDouble(),
                    color: theme.colorScheme.primary.withOpacity(0.07),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tone Donut Chart
// ─────────────────────────────────────────────────────────────────────────────

class _ToneDonutChart extends StatelessWidget {
  const _ToneDonutChart({required this.toneCounts, required this.total});
  final Map<ToneType, int> toneCounts;
  final int total;

  @override
  Widget build(BuildContext context) {
    final sections = ToneType.values
        .where((t) => (toneCounts[t] ?? 0) > 0)
        .map((t) {
          final count = toneCounts[t]!;
          final pct = count / total * 100;
          return PieChartSectionData(
            value: count.toDouble(),
            color: t.color,
            title: '${pct.round()}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          );
        })
        .toList();

    if (sections.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 180,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tone Breakdown List
// ─────────────────────────────────────────────────────────────────────────────

class _ToneBreakdownList extends StatelessWidget {
  const _ToneBreakdownList({required this.toneCounts, required this.total});
  final Map<ToneType, int> toneCounts;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = ToneType.values.toList()
      ..sort((a, b) => (toneCounts[b] ?? 0).compareTo(toneCounts[a] ?? 0));

    return Column(
      children: sorted.map((tone) {
        final count = toneCounts[tone] ?? 0;
        final pct = total == 0 ? 0.0 : count / total;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Text(tone.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                child: Text(tone.label,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: tone.color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation(tone.color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 32,
                child: Text(
                  '$count',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 56, color: theme.colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No data yet',
            style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ),
          const SizedBox(height: 8),
          Text(
            'Rewrite some messages to see your tone usage patterns here.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.3)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
