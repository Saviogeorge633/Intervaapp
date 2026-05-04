import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/build_session_provider.dart';
import '../models/history_entry.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  List<BarChartGroupData> _generateChartData(List<HistoryEntry> entries, Color barColor) {
    final now = DateTime.now();
    final Map<int, int> minutesPerDay = {};

    for (int i = 0; i < 7; i++) {
      minutesPerDay[i] = 0;
    }

    for (var entry in entries) {
      final entryDate = DateTime(entry.completedAt.year, entry.completedAt.month, entry.completedAt.day);
      final todayDate = DateTime(now.year, now.month, now.day);
      final dayDiff = todayDate.difference(entryDate).inDays;
      if (dayDiff >= 0 && dayDiff < 7) {
        minutesPerDay[dayDiff] = (minutesPerDay[dayDiff] ?? 0) + (entry.durationSeconds ~/ 60);
      }
    }

    return List.generate(7, (index) {
      final dayOffset = 6 - index;
      final val = (minutesPerDay[dayOffset] ?? 0).toDouble();
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: val,
            color: barColor,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      );
    });
  }

  Widget _buildStatCard(BuildContext context, AppColors colors, {required String title, required String value, String? subtitle, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(colors.isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.accent, size: 28),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: colors.mutedText, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: colors.primaryText, fontSize: 24, fontWeight: FontWeight.bold)),
          if (subtitle != null) Text(subtitle, style: TextStyle(color: colors.mutedText, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuildSessionProvider>();
    final entries = provider.storageService.getHistoryEntries();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors(isDark);

    final totalSeconds = entries.fold<int>(0, (sum, item) => sum + item.durationSeconds);
    final totalMinutes = totalSeconds ~/ 60;
    final totalHours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History & Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    colors,
                    title: "Total Time",
                    value: totalHours > 0 ? "${totalHours}h ${remainingMinutes}m" : "${remainingMinutes}m",
                    icon: Icons.access_time,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    colors,
                    title: "Completed",
                    value: "${entries.length}",
                    subtitle: "Sessions",
                    icon: Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text("Last 7 Days (Minutes)", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: null,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final dayOffset = 6 - value.toInt();
                          final date = DateTime.now().subtract(Duration(days: dayOffset));
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          final weekday = days[date.weekday - 1];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(weekday, style: TextStyle(color: colors.mutedText, fontSize: 12)),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _generateChartData(entries, colors.accent),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text("Recent History", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            entries.isEmpty 
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text("No history yet.", style: TextStyle(color: colors.mutedText)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length > 20 ? 20 : entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[entries.length - 1 - index];
                    
                    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    final m = months[entry.completedAt.month - 1];
                    final d = entry.completedAt.day;
                    
                    int h = entry.completedAt.hour;
                    final ampm = h >= 12 ? 'PM' : 'AM';
                    h = h % 12;
                    if (h == 0) h = 12;
                    final min = entry.completedAt.minute.toString().padLeft(2, '0');
                    final dateStr = "$m $d, $h:$min $ampm";
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(colors.isDark ? 0.2 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          )
                        ]
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.background,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.timer, color: colors.accent, size: 20),
                        ),
                        title: Text(entry.intervalName, style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.bold)),
                        subtitle: Text(dateStr, style: TextStyle(color: colors.mutedText, fontSize: 12)),
                        trailing: Text(
                          "${entry.durationSeconds ~/ 60}:${(entry.durationSeconds % 60).toString().padLeft(2, '0')}", 
                          style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                      ),
                    );
                  },
                ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
