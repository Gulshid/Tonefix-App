import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/features/history/bloc/history_bloc.dart';
import 'package:tonefix/routes/app_router.dart';
import 'package:tonefix/shared/models/tone_models.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
        ),
        actions: [
          BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (state is HistoryLoaded && state.items.isNotEmpty) {
                return TextButton(
                  onPressed: () => context
                      .read<HistoryBloc>()
                      .add(const HistoryClearEvent()),
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      color: AppColors.error,
                      fontFamily: 'Poppins',
                      fontSize: 13.sp,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HistoryLoaded) {
            if (state.items.isEmpty) {
              return _EmptyState();
            }
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 40.h),
              physics: const BouncingScrollPhysics(),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return _HistoryCard(
                  result: item,
                  index: index,
                  onTap: () => context.push(AppRoutes.rewrite, extra: item),
                  onDelete: () => context
                      .read<HistoryBloc>()
                      .add(HistoryDeleteEvent(item.id)),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.result,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  final RewriteResult result;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = result.tone;

    return Dismissible(
      key: Key(result.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 22.sp),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
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
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: tone.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '${tone.emoji} ${tone.label}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: tone.color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(result.createdAt),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.sp,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                result.rewrittenText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.sp,
                  height: 1.55,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 50 * index))
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.08, end: 0, duration: 350.ms, curve: Curves.easeOut),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 54.sp, color: AppColors.borderLight),
          SizedBox(height: 16.h),
          Text(
            'No history yet',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryLight,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Your rewrites will appear here.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13.sp,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
