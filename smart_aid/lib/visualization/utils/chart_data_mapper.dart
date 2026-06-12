import '../models/chart_point.dart';
import '../../analytics/models/medication_adherence_stats.dart';

class ChartDataMapper {
  /// Converts raw analytics timeline points into UI-ready chart points.
  /// Expects the timeline to be sorted oldest-to-newest.
  static List<ChartPoint> mapTimelineToWeeklyTrend(List<AdherenceTimelinePoint> timeline) {
    final List<ChartPoint> points = [];
    
    for (int i = 0; i < timeline.length; i++) {
      final point = timeline[i];
      DateTime dt;
      try {
        dt = DateTime.parse(point.dateKey);
      } catch (_) {
        dt = DateTime.now();
      }
      
      final weekday = _getWeekdayAbbr(dt.weekday);
      final isToday = i == timeline.length - 1; // Highlight the most recent day (today)
      
      points.add(ChartPoint(
        label: weekday,
        normalizedValue: point.percentage / 100.0,
        isHighlight: isToday,
      ));
    }
    
    return points;
  }
  
  static String _getWeekdayAbbr(int weekday) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    if (weekday >= 1 && weekday <= 7) return days[weekday - 1];
    return '';
  }
}
