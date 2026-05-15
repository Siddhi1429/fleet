import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../shared/models/vehicle.dart';
import '../data/mock_socket_service.dart';

class TrackingState {
  final Vehicle? vehicle;
  final List<LatLng> routeHistory;
  final SocketConnectionState connectionState;
  final String connectionLabel;
  final bool isDuplicate;
  final bool isStale;

  const TrackingState({
    this.vehicle,
    this.routeHistory = const [],
    this.connectionState = SocketConnectionState.connecting,
    this.connectionLabel = 'Connecting…',
    this.isDuplicate = false,
    this.isStale = false,
  });

  TrackingState copyWith({
    Vehicle? vehicle,
    List<LatLng>? routeHistory,
    SocketConnectionState? connectionState,
    String? connectionLabel,
    bool? isDuplicate,
    bool? isStale,
  }) {
    return TrackingState(
      vehicle: vehicle ?? this.vehicle,
      routeHistory: routeHistory ?? this.routeHistory,
      connectionState: connectionState ?? this.connectionState,
      connectionLabel: connectionLabel ?? this.connectionLabel,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      isStale: isStale ?? this.isStale,
    );
  }
}

class TrackingNotifier extends FamilyNotifier<TrackingState, String> {
  late MockSocketService _socket;
  StreamSubscription? _eventSub;
  StreamSubscription? _stateSub;

  @override
  TrackingState build(String vehicleId) {
    _socket = MockSocketService(vehicleId: vehicleId);

    _stateSub = _socket.connectionState.listen((s) {
      state = state.copyWith(
        connectionState: s,
        connectionLabel: _label(s),
      );
    });

    _eventSub = _socket.events.listen((event) {
      if (event.isDuplicate || event.isStale) {
        state = state.copyWith(
          isDuplicate: event.isDuplicate,
          isStale: event.isStale,
        );
        return;
      }

      final newPoint = LatLng(
        event.vehicle.latitude,
        event.vehicle.longitude,
      );

      final history = [...state.routeHistory, newPoint];
      final trimmed = history.length > 100
          ? history.sublist(history.length - 100)
          : history;

      state = state.copyWith(
        vehicle: event.vehicle,
        routeHistory: trimmed,
        isDuplicate: false,
        isStale: false,
      );
    });

    _socket.connect();

    ref.onDispose(() {
      _eventSub?.cancel();
      _stateSub?.cancel();
      _socket.dispose();
    });

    return const TrackingState();
  }

  String _label(SocketConnectionState s) {
    switch (s) {
      case SocketConnectionState.connecting:
        return 'Connecting…';
      case SocketConnectionState.connected:
        return 'Live';
      case SocketConnectionState.disconnected:
        return 'Disconnected';
      case SocketConnectionState.reconnecting:
        return 'Reconnecting…';
    }
  }

  void simulateDisconnect() => _socket.disconnect();
  void reconnect() => _socket.connect();
}

final trackingProvider =
    NotifierProviderFamily<TrackingNotifier, TrackingState, String>(
  TrackingNotifier.new,
);
