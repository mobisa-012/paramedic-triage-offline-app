import 'dart:math';
import 'package:paramedic_triage/core/domain/triage_record.dart';

abstract class TriageApiClient {
  Future<void> postTriage(TriageRecord record);
}

class APIException implements Exception {
  final String message;

  APIException(this.message);
  @override
  String toString() => message;
}

// simulation post request `POST /ap1/v1/triage`

class MockAPIClient implements TriageApiClient {
  final Duration delay;
  final double randomFailuresRate;
  final Random _random;
  bool simulateFailure = false;

  MockAPIClient({
    this.delay = const Duration(seconds: 2), 
    this.randomFailuresRate = 0.5,
    Random? random,
  }) : _random = random ?? Random();

  @override
  Future<void>postTriage(TriageRecord record) async {
    await Future<void>.delayed(delay);
    if(simulateFailure || _random.nextDouble() < randomFailuresRate) {
      throw APIException("'POST /api/v1/triage failed (simulated 503)");
    }
  }
}
