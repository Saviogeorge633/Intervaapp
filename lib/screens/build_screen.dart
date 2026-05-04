import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:provider/provider.dart';
import '../providers/build_session_provider.dart';
import '../models/active_session_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../widgets/timer_card.dart';
import '../widgets/input_field.dart';
import '../theme/app_theme.dart';
import 'add_interval_sheet.dart';
import 'active_timer_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import '../services/timer_service.dart';

class BuildScreen extends StatefulWidget {
  const BuildScreen({Key? key}) : super(key: key);

  @override
  _BuildScreenState createState() => _BuildScreenState();
}

class _BuildScreenState extends State<BuildScreen> {
  StreamSubscription? _updateSub;
  StreamSubscription? _completedSub;
  ActiveSessionState? _activeState;
  bool _isRunning = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUnfinishedSession();
    });
    
    _checkRunningService();
    
    _updateSub = FlutterBackgroundService().on('update').listen((event) {
      if (event != null && mounted) {
        setState(() {
          _isRunning = true;
          _activeState = ActiveSessionState.fromJson(Map<String, dynamic>.from(event));
        });
      }
    });
    
    _completedSub = FlutterBackgroundService().on('completed').listen((event) {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _activeState = null;
        });
      }
    });
  }

  void _checkRunningService() async {
    final running = await FlutterBackgroundService().isRunning();
    if (mounted) {
      setState(() {
        _isRunning = running;
      });
    }
  }

  @override
  void dispose() {
    _updateSub?.cancel();
    _completedSub?.cancel();
    super.dispose();
  }

  void _checkUnfinishedSession() {
    final provider = context.read<BuildSessionProvider>();
    final state = provider.storageService.loadActiveSession();
    
    if (state != null && state.intervals.isNotEmpty && !_isRunning) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Resume Session?"),
          content: const Text("You have an unfinished timer session. Would you like to resume it?"),
          actions: [
            TextButton(
              onPressed: () {
                TimerService().stopSession();
                provider.storageService.clearActiveSession();
                Navigator.pop(context);
              },
              child: const Text("Discard", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveTimerScreen(
                      intervals: state.intervals,
                      resumingState: state,
                    ),
                  ),
                );
              },
              child: const Text("Resume"),
            ),
          ],
        ),
      );
    }
  }

  void _showAddInterval(BuildContext context, BuildSessionProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddIntervalSheet(
        onSave: (name, duration, color) {
          provider.addInterval(name, duration, color);
        },
      ),
    );
  }

  void _showEditInterval(BuildContext context, BuildSessionProvider provider, int index) {
    final interval = provider.currentIntervals[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddIntervalSheet(
        initialId: interval.id,
        initialName: interval.name,
        initialDurationSeconds: interval.durationSeconds,
        initialColorValue: interval.colorValue,
        onSave: (name, duration, color) {
          provider.editInterval(interval.id, name, duration, color);
        },
      ),
    );
  }

  Widget _buildMiniPlayer(AppColors colors) {
    if (!_isRunning || _activeState == null || _activeState!.intervals.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final currentInterval = _activeState!.intervals[_activeState!.currentIndex];
    final min = _activeState!.secondsLeft ~/ 60;
    final sec = _activeState!.secondsLeft % 60;
    final timeStr = '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveTimerScreen(
              intervals: _activeState!.intervals,
              resumingState: _activeState,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(colors.isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, -4))
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Color(currentInterval.colorValue),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currentInterval.name, style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText, fontSize: 16)),
                    Text("Tap to open timer", style: TextStyle(fontSize: 12, color: colors.mutedText)),
                  ],
                ),
              ),
              Text(timeStr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: colors.primaryText, fontFamily: 'monospace')),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: colors.background,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.stop, color: colors.warning),
                  onPressed: () {
                     TimerService().stopSession();
                     context.read<BuildSessionProvider>().storageService.clearActiveSession();
                     setState(() {
                       _isRunning = false;
                       _activeState = null;
                     });
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuildSessionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors(isDark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interva', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: InputField(
                      label: "Set Name",
                      controller: TextEditingController(text: provider.currentSessionName)
                        ..selection = TextSelection.collapsed(offset: provider.currentSessionName.length),
                      onChanged: (val) => context.read<BuildSessionProvider>().setSessionName(val),
                    ),
                  ),
                  if (provider.currentIntervals.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                      child: Center(
                        child: Text(
                          "No intervals added yet.\nTap + to create one.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.mutedText, fontSize: 16),
                        ),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: provider.currentIntervals.length,
                      onReorder: (oldIndex, newIndex) {
                        context.read<BuildSessionProvider>().reorderIntervals(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final interval = provider.currentIntervals[index];
                        return Container(
                          key: ValueKey(interval.id),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: TimerCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Color(interval.colorValue),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        interval.name,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "${interval.durationSeconds ~/ 60}:${(interval.durationSeconds % 60).toString().padLeft(2, '0')}",
                                        style: TextStyle(color: colors.mutedText),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: colors.mutedText, size: 20),
                                  onPressed: () => _showEditInterval(context, provider, index),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: colors.warning, size: 20),
                                  onPressed: () {
                                    context.read<BuildSessionProvider>().removeInterval(interval.id);
                                  },
                                ),
                                Icon(Icons.drag_handle, color: colors.mutedText),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  if (provider.templates.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Text(
                        "My Presets",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: provider.templates.length,
                      itemBuilder: (context, index) {
                        final template = provider.templates[index];
                        final totalSeconds = template.intervals.fold<int>(0, (sum, i) => sum + i.durationSeconds);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              provider.loadTemplate(template);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loaded ${template.name}')));
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: TimerCard(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Row(
                                children: [
                                  Icon(Icons.query_builder, color: colors.primaryText, size: 28),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          template.name,
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "${totalSeconds ~/ 60} mins",
                                          style: TextStyle(color: colors.mutedText),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.play_arrow, color: colors.accent),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ActiveTimerScreen(intervals: template.intervals),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: colors.warning, size: 20),
                                    onPressed: () {
                                      provider.removeTemplate(template.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 100), // Spacing for FAB
                ],
              ),
            ),
          ),
          if (_isRunning && _activeState != null)
            _buildMiniPlayer(colors)
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surface,
                boxShadow: [
                  if (!isDark)
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        text: "Save Set",
                        onPressed: provider.currentIntervals.isEmpty ? null : () {
                          provider.saveCurrentAsTemplate();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Template Saved!')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryButton(
                        text: "Start",
                        onPressed: provider.currentIntervals.isEmpty ? null : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActiveTimerScreen(intervals: provider.currentIntervals),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: (_isRunning && _activeState != null) ? 100.0 : 80.0), // Above bottom bar
        child: FloatingActionButton(
          backgroundColor: colors.accent,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _showAddInterval(context, provider),
        ),
      ),
    );
  }
}
