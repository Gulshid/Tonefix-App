import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/core/services/tone_engine.dart';
import 'package:tonefix/shared/models/tone_models.dart';

/// Phase 4 – Task 3: Shows AI-recommended tones with confidence scores.
/// Triggered when user has typed enough text.
class ToneRecommenderWidget extends StatefulWidget {
  const ToneRecommenderWidget({
    super.key,
    required this.text,
    required this.toneEngine,
    required this.onToneSelected,
  });

  final String text;
  final ToneEngine toneEngine;
  final void Function(ToneType) onToneSelected;

  @override
  State<ToneRecommenderWidget> createState() => _ToneRecommenderWidgetState();
}

class _ToneRecommenderWidgetState extends State<ToneRecommenderWidget> {
  List<ToneRecommendation>? _recommendations;
  bool _loading = false;
  String? _lastAnalyzed;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  @override
  void didUpdateWidget(ToneRecommenderWidget old) {
    super.didUpdateWidget(old);
    if (widget.text != old.text) _analyze();
  }

  Future<void> _analyze() async {
    if (widget.text.trim().length < 20) {
      setState(() => _recommendations = null);
      return;
    }
    if (widget.text == _lastAnalyzed) return;
    _lastAnalyzed = widget.text;

    setState(() => _loading = true);
    try {
      final recs = await widget.toneEngine.recommendTone(widget.text);
      if (!mounted) return;
      setState(() {
        _recommendations = recs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          children: [
            SizedBox(
              width: 14.r,
              height: 14.r,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'Analysing tone…',
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    final recs = _recommendations;
    if (recs == null || recs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 14.sp, color: AppColors.primary),
              SizedBox(width: 5.w),
              Text(
                'AI SUGGESTS',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: recs.take(3).map((rec) {
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: GestureDetector(
                  onTap: () => widget.onToneSelected(rec.tone),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: rec.tone.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                          color: rec.tone.color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(rec.tone.emoji,
                            style: TextStyle(fontSize: 13.sp)),
                        SizedBox(width: 5.w),
                        Text(
                          rec.tone.label,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: rec.tone.color,
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 5.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: rec.tone.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '${rec.score}%',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: rec.tone.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 4.h),
          if (recs.isNotEmpty)
            Text(
              recs.first.reason,
              style: TextStyle(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
