import 'dart:async';
import 'dart:math';
import '../../../shared/models/vehicle.dart';

enum SocketConnectionState {
  connecting,
  connected,
  disconnected,
  reconnecting,
}

class SocketEvent {
  final Vehicle vehicle;
  final DateTime receivedAt;
  final bool isDuplicate;
  final bool isStale;

  SocketEvent({
    required this.vehicle,
    required this.receivedAt,
    this.isDuplicate = false,
    this.isStale = false,
  });
}

class MockSocketService {
  final String vehicleId;

  final _eventController = StreamController<SocketEvent>.broadcast();
  final _stateController =
      StreamController<SocketConnectionState>.broadcast();

  Timer? _updateTimer;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  final Random _random = Random();
  bool _isConnected = false;

  double _lat;
  double _lng;
  double _fuel;
  double _speed;
  double _deliveryProgress;
  int _sequenceId = 0;
  int _lastSequenceId = -1;

  int _updateCount = 0;

  MockSocketService({
    required this.vehicleId,
    double startLat = 37.7749,
    double startLng = -122.4194,
    double startFuel = 0.85,
  })  : _lat = startLat + (_rng.nextDouble() - 0.5) * 0.05,
        _lng = startLng + (_rng.nextDouble() - 0.5) * 0.05,
        _fuel = startFuel,
        _speed = 30 + _rng.nextDouble() * 50,
        _deliveryProgress = _rng.nextDouble() * 0.5;

  static final Random _rng = Random();

  Stream<SocketEvent> get events => _eventController.stream;
  Stream<SocketConnectionState> get connectionState => _stateController.stream;
  bool get isConnected => _isConnected;

  void connect() {
    if (_isConnected) return;
    _stateController.add(SocketConnectionState.connecting);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (_eventController.isClosed) return;
      _isConnected = true;
      _stateController.add(SocketConnectionState.connected);
      _startUpdates();
      _startHeartbeat();
    });
  }

  void _startUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isConnected) return;

      _updateCount++;

      if (_updateCount % 15 == 0 && _updateCount > 0) {
        _simulateDisconnect();
        return;
      }

      if (_updateCount % 7 == 0) {
        _emitDuplicate();
        return;
      }

      _emitUpdate();
    });
  }

  void _emitUpdate() {
    _lat += (_random.nextDouble() - 0.5) * 0.0012;
    _lng += (_random.nextDouble() - 0.5) * 0.0012;
    _fuel = max(0.05, _fuel - 0.003);
    _speed = (30 + _random.nextDouble() * 70).clamp(0, 120);
    _deliveryProgress = min(1.0, _deliveryProgress + 0.008);
    _sequenceId++;

    final isStale = _sequenceId <= _lastSequenceId;
    if (!isStale) _lastSequenceId = _sequenceId;

    final vehicle = _buildVehicle();
    _eventController.add(SocketEvent(
      vehicle: vehicle,
      receivedAt: DateTime.now(),
      isDuplicate: false,
      isStale: isStale,
    ));
  }

  void _emitDuplicate() {
    final vehicle = _buildVehicle();
    _eventController.add(SocketEvent(
      vehicle: vehicle,
      receivedAt: DateTime.now(),
      isDuplicate: true,
    ));
  }

  void _startHeartbeat() {
    _heartbeatTimer =
        Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_isConnected) return;
    });
  }

  void _simulateDisconnect() {
    _isConnected = false;
    _updateTimer?.cancel();
    _stateController.add(SocketConnectionState.disconnected);

    final delay = 4 + _random.nextInt(3);
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (_stateController.isClosed) return;
      _stateController.add(SocketConnectionState.reconnecting);
      Future.delayed(const Duration(seconds: 2), () {
        if (_stateController.isClosed) return;
        _isConnected = true;
        _stateController.add(SocketConnectionState.connected);
        _startUpdates();
      });
    });
  }

  void disconnect() {
    _isConnected = false;
    _updateTimer?.cancel();
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _stateController.add(SocketConnectionState.disconnected);
  }

  Vehicle _buildVehicle() {
    final etaMinutes = max(0, (100 - _deliveryProgress * 100).toInt() ~/ 2);
    return Vehicle(
      id: vehicleId,
      driverName: 'Driver of $vehicleId',
      vehicleType: 'Heavy Truck',
      currentSpeed: _speed,
      status: 'Online',
      lastUpdated: DateTime.now(),
      deliveryProgress: _deliveryProgress,
      latitude: _lat,
      longitude: _lng,
      fuelLevel: _fuel,
      eta: etaMinutes < 2 ? 'Arrived' : '$etaMinutes min',
      connectionQuality: 70 + _random.nextInt(30),
    );
  }

  void dispose() {
    disconnect();
    if (!_eventController.isClosed) _eventController.close();
    if (!_stateController.isClosed) _stateController.close();
  }
}
