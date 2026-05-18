import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/build_session_provider.dart';
import '../models/history_entry.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int? _touchedBarIndex;
  // Tracks which day groups are collapsed (true = collapsed)
  final Map<String, bool> _collapsed = {};

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _fmtTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Returns a map of dayOffset → total actual seconds (0 = today, 6 = 6 days ago)
  Map<int, int> _buildDayMap(List<HistoryEntry> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final Map<int, int> map = {for (int i = 0; i < 7; i++) i: 0};
    for (final e in entries) {
      final entryDay = DateTime(e.completedAt.year, e.completedAt.month, e.completedAt.day);
      final diff = today.difference(entryDay).inDays;
      if (diff >= 0 && diff < 7) {
        map[diff] = (map[diff] ?? 0) + e.actualSeconds;
      }
    }
    return map;
  }

  /// Groups entries by day label ("Today", "Yesterday", "Mon, May 5", …)
  List<MapEntry<String, List<HistoryEntry>>> _groupByDay(List<HistoryEntry> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    final Map<String, List<HistoryEntry>> groups = {};
    final List<String> keyOrder = [];

    // newest first
    final sorted = entries.reversed.toList();

    for (final e in sorted) {
      final entryDay = DateTime(e.completedAt.year, e.completedAt.month, e.completedAt.day);
      final diff = today.difference(entryDay).inDays;

      String label;
      if (diff == 0) {
        label = 'Today - ${months[entryDay.month - 1]} ${entryDay.day}';
      } else if (diff == 1) {
        label = 'Yesterday - ${months[entryDay.month - 1]} ${entryDay.day}';
      } else {
        const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
        label = '${days[entryDay.weekday - 1]}, ${months[entryDay.month - 1]} ${entryDay.day}';
      }

      if (!groups.containsKey(label)) {
        groups[label] = [];
        keyOrder.add(label);
      }
      groups[label]!.add(e);
    }

    return keyOrder.map((k) => MapEntry(k, groups[k]!)).toList();
  }

  // ── Chart ─────────────────────────────────────────────────────────────────

  List<BarChartGroupData> _buildBarGroups(
    Map<int, int> dayMap,
    Color barColor,
    Color touchedColor,
  ) {
    return List.generate(7, (index) {
      // index 0 = 6 days ago, index 6 = today
      final dayOffset = 6 - index;
      final seconds = dayMap[dayOffset] ?? 0;
      final minutes = seconds / 60;
      final isTouched = _touchedBarIndex == index;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: minutes,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: isTouched
                  ? [touchedColor, touchedColor.withOpacity(0.7)]
                  : [barColor, barColor.withOpacity(0.6)],
            ),
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
        showingTooltipIndicators: isTouched ? [0] : [],
      );
    });
  }

  // ── UI Widgets ────────────────────────────────────────────────────────────

  Widget _buildChart(List<HistoryEntry> entries, AppColors colors) {
    final dayMap = _buildDayMap(entries);
    final maxMinutes = dayMap.values.fold<int>(0, (a, b) => a > b ? a : b) / 60;
    final chartMax = (maxMinutes < 1) ? 10.0 : (maxMinutes * 1.25).ceilToDouble();

    // Y-axis interval
    double yInterval = (chartMax / 4).ceilToDouble();
    if (yInterval < 1) yInterval = 1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMax,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
            if (event is FlPointerHoverEvent || event is FlTapUpEvent || event is FlPanUpdateEvent) {
              setState(() {
                if (response != null && response.spot != null) {
                  _touchedBarIndex = response.spot!.touchedBarGroupIndex;
                } else {
                  _touchedBarIndex = null;
                }
              });
            }
            if (event is FlTapUpEvent || event is FlLongPressEnd || event is FlPanEndEvent) {
              // keep showing until next tap elsewhere
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dayOffset = 6 - group.x;
              final date = DateTime.now().subtract(Duration(days: dayOffset));
              const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
              const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
              final dayName = days[date.weekday - 1];
              final dayLabel = '${months[date.month - 1]} ${date.day}';
              final totalMins = rod.toY.round();
              return BarTooltipItem(
                '$dayName, $dayLabel\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                children: [
                  TextSpan(
                    text: '${totalMins}m total',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.normal),
                  ),
                ],
              );
            },
            fitInsideHorizontally: true,
            fitInsideVertically: true,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final dayOffset = 6 - value.toInt();
                final date = DateTime.now().subtract(Duration(days: dayOffset));
                const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    days[date.weekday - 1],
                    style: TextStyle(color: colors.mutedText, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return Text('0m', style: TextStyle(color: colors.mutedText, fontSize: 10));
                }
                return Text('${value.toInt()}m', style: TextStyle(color: colors.mutedText, fontSize: 10));
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colors.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _buildBarGroups(dayMap, colors.accent, colors.accent.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildHistoryEntry(HistoryEntry entry, AppColors colors) {
    final progress = entry.durationSeconds > 0
        ? (entry.actualSeconds / entry.durationSeconds).clamp(0.0, 1.0)
        : 1.0;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final m = months[entry.completedAt.month - 1];
    final d = entry.completedAt.day;
    int h = entry.completedAt.hour;
    final ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    final min = entry.completedAt.minute.toString().padLeft(2, '0');
    final dateStr = '$m $d, $h:$min $ampm';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.timer_outlined, color: colors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          // Name + progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.intervalName,
                    style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(dateStr, style: TextStyle(color: colors.mutedText, fontSize: 12)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: colors.isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Time + "of" label
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtTime(entry.actualSeconds),
                style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (!entry.isCompleted)
                Text(
                  'of ${_fmtTime(entry.durationSeconds)}',
                  style: TextStyle(color: colors.mutedText, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: colors.mutedText, size: 18),
        ],
      ),
    );
  }

  Widget _buildDayGroup(String label, List<HistoryEntry> dayEntries, AppColors colors) {
    final isCollapsed = _collapsed[label] ?? false;
    final totalSecs = dayEntries.fold<int>(0, (s, e) => s + e.actualSeconds);
    final count = dayEntries.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(colors.isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Day header
          InkWell(
            onTap: () => setState(() => _collapsed[label] = !isCollapsed),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: isCollapsed ? const Radius.circular(16) : Radius.zero,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Text(
                    '$count session${count != 1 ? 's' : ''}',
                    style: TextStyle(color: colors.mutedText, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isCollapsed ? -0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: colors.mutedText, size: 20),
                  ),
                ],
              ),
            ),
          ),
          // Entries
          if (!isCollapsed)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Column(
                children: dayEntries.map((e) => _buildHistoryEntry(e, colors)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuildSessionProvider>();
    final entries = provider.storageService.getHistoryEntries();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors(isDark);

    final totalSeconds = entries.fold<int>(0, (s, e) => s + e.actualSeconds);
    final totalMinutes = totalSeconds ~/ 60;
    final totalHours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;
    final totalTimeStr = totalHours > 0 ? '${totalHours}h ${remainingMinutes}m' : '${totalMinutes}m';

    final groups = _groupByDay(entries);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History & Analytics'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stat cards ──
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(colors, title: 'Total Time', value: totalTimeStr, icon: Icons.access_time_rounded),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(colors, title: 'Sessions', value: '${entries.length}', icon: Icons.check_circle_outline_rounded),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Chart header ──
            Text(
              'Last 7 Days (Minutes)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // ── Bar chart ──
            SizedBox(
              height: 240,
              child: _buildChart(entries, colors),
            ),

            const SizedBox(height: 36),

            // ── Recent history header ──
            Text(
              'Recent History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ── Day groups ──
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('No history yet.', style: TextStyle(color: colors.mutedText, fontSize: 15)),
                ),
              )
            else
              ...groups.map((g) => _buildDayGroup(g.key, g.value, colors)),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(AppColors colors, {required String title, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(colors.isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.accent, size: 26),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(color: colors.mutedText, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: colors.primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
