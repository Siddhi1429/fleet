import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiagnosticsState {
  final int activeApiCalls;
  final int cachedRecordsCount;
  final int offlineQueueCount;
  final String socketStatus;
  final List<String> recentLogs;
  final int totalApiCalls;
  final int totalErrors;
  final DateTime? lastSync;
  final double avgLatencyMs;

  const DiagnosticsState({
    this.activeApiCalls = 0,
    this.cachedRecordsCount = 0,
    this.offlineQueueCount = 0,
    this.socketStatus = 'Disconnected',
    this.recentLogs = const [],
    this.totalApiCalls = 0,
    this.totalErrors = 0,
    this.lastSync,
    this.avgLatencyMs = 0,
  });

  DiagnosticsState copyWith({
    int? activeApiCalls,
    int? cachedRecordsCount,
    int? offlineQueueCount,
    String? socketStatus,
    List<String>? recentLogs,
    int? totalApiCalls,
    int? totalErrors,
    DateTime? lastSync,
    double? avgLatencyMs,
  }) {
    return DiagnosticsState(
      activeApiCalls: activeApiCalls ?? this.activeApiCalls,
      cachedRecordsCount: cachedRecordsCount ?? this.cachedRecordsCount,
      offlineQueueCount: offlineQueueCount ?? this.offlineQueueCount,
      socketStatus: socketStatus ?? this.socketStatus,
      recentLogs: recentLogs ?? this.recentLogs,
      totalApiCalls: totalApiCalls ?? this.totalApiCalls,
      totalErrors: totalErrors ?? this.totalErrors,
      lastSync: lastSync ?? this.lastSync,
      avgLatencyMs: avgLatencyMs ?? this.avgLatencyMs,
    );
  }
}

class DiagnosticsNotifier extends Notifier<DiagnosticsState> {
  @override
  DiagnosticsState build() => const DiagnosticsState();

  void incrementApiCall() {
    state = state.copyWith(
      activeApiCalls: state.activeApiCalls + 1,
      totalApiCalls: state.totalApiCalls + 1,
    );
  }

  void decrementApiCall() {
    state = state.copyWith(
      activeApiCalls: state.activeApiCalls > 0
          ? state.activeApiCalls - 1
          : 0,
      lastSync: DateTime.now(),
    );
  }

  void recordError() {
    state = state.copyWith(totalErrors: state.totalErrors + 1);
  }

  void setSocketStatus(String status) {
    state = state.copyWith(socketStatus: status);
  }

  void updateCacheCounts({
    required int cachedRecords,
    required int offlineQueue,
  }) {
    state = state.copyWith(
      cachedRecordsCount: cachedRecords,
      offlineQueueCount: offlineQueue,
    );
  }

  void addLog(String message) {
    final timestamp =
        '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}';
    final entry = '[$timestamp] $message';
    final updated = [entry, ...state.recentLogs];
    state = state.copyWith(
      recentLogs: updated.length > 80 ? updated.sublist(0, 80) : updated,
    );
  }

  void clearLogs() {
    state = state.copyWith(recentLogs: []);
  }
}

final diagnosticsProvider =
    NotifierProvider<DiagnosticsNotifier, DiagnosticsState>(
  DiagnosticsNotifier.new,
);
