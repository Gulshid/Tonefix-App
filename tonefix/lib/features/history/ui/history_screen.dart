import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/features/history/bloc/history_bloc.dart';
import 'package:tonefix/shared/models/tone_models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (state is! HistoryLoaded || state.items.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: Icon(Icons.delete_sweep_rounded, size: 22.sp),
                onPressed: _confirmClear,
                tooltip: 'Clear all',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search history...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),

          // List
          Expanded(
            child: BlocBuilder<HistoryBloc, HistoryState>(
              builder: (context, state) {
                if (state is HistoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is HistoryError) {
                  return Center(child: Text(state.message));
                }
                if (state is HistoryLoaded) {
                  final filtered = _searchQuery.isEmpty
                      ? state.items
                      : state.items
                          .where(
                            (i) =>
                                i.originalText
                                    .toLowerCase()
                                    .contains(_searchQuery) ||
                                i.rewrittenText
                                    .toLowerCase()
                                    .contains(_searchQuery),
                          )
                          .toList();

                  if (filtered.isEmpty) {
                    return _EmptyHistory(hasSearch: _searchQuery.isNotEmpty);
                  }

                  return ListView.separated(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      return _HistoryCard(
                        result: filtered[index],
                        onDelete: () {
                          context.read<HistoryBloc>().add(
                                HistoryDeleteEvent(filtered[index].id),
                              );
                        },
                      )
                          .animate(delay: Duration(milliseconds: index * 50))
                          .fadeIn(duration: 300.ms)
                          .slideX(begin: 0.1, end: 0);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Delete all rewrite history? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<HistoryBloc>().add(const HistoryClearEvent());
            },
            child: Text(
              'Clear All',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.result, required this.onDelete});

  final RewriteResult result;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('MMM d, h:mm a').format(result.createdAt);

    return Dismissible(
      key: Key(result.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(Icons.delete_rounded, color: AppColors.error, size: 24.sp),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // BLoC handles the UI update
      },
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tone badge + date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      result.tone.emoji,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      result.tone.label,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: result.tone.color,
                      ),
                    ),
                  ],
                ),
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Original preview
            Text(
              result.originalText,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 6.h),

            // Divider
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    height: 1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    size: 12.sp,
                    color: result.tone.color.withValues(alpha: 0.7),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    height: 1,
                  ),
                ),
              ],
            ),

            SizedBox(height: 6.h),

            // Rewritten preview
            Text(
              result.rewrittenText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: result.tone.color,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.hasSearch});
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch ? Icons.search_off_rounded : Icons.history_rounded,
            size: 56.sp,
            color: AppColors.primary.withOpacity(0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            hasSearch ? 'No results found' : 'No rewrites yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8.h),
          Text(
            hasSearch
                ? 'Try a different search term'
                : 'Your rewrite history will appear here',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
