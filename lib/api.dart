import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'api.freezed.dart';
part 'api.g.dart';

@freezed
class AppState with _$AppState {
  const factory AppState({
    List<Record>? records,
  }) = _AppState;
}

class Api extends Cubit<AppState> {
  final Dio _dio = Dio();
  final Random r = Random();

  DateTime _referenceDate = DateTime.now().subtract(const Duration(days: 1));

  Api() : super(const AppState()) {
    getRecords().then(
      (value) => emit(
        state.copyWith(records: value),
      ),
    );

    Timer.periodic(const Duration(seconds: 2), (timer) async {
      var records = await getRecords();
      emit(state.copyWith(
        records: records,
      ));
    });
  }

  Future<List<Record>> getRecords() async {
    var response = await _dio.get(
      'https://mirai-tracker2.markovvn1.ru/chart',
      queryParameters: {
        'start': _referenceDate.toString(),
        'stop': DateTime.now().toString(),
      },
      options: Options(
        headers: {
          'Access-Control-Allow-Origin': '*',
        },
      ),
    );
    return List.generate(response.data.length, (index) {
      return Record(
        timestamp: DateTime.parse(response.data[index]['timestamp']).toLocal(),
        recieved: DateTime.parse(response.data[index]['recieved']).toLocal(),
        temperature: response.data[index]['temperature'],
        humidity: response.data[index]['humidity'],
        battery: response.data[index]['battery'],
        location: response.data[index]['location'] != null
            ? Location(
                latitude: response.data[index]['location']['latitude'],
                longitude: response.data[index]['location']['longitude'],
              )
            : null,
      );
    });
  }

  Future<List<Record>> getRecordsFake() async {
    var a = 1000000;
    var list = List.generate(500, (index) {
      return Record(
        timestamp: DateTime.fromMillisecondsSinceEpoch(a += r.nextInt(1000)),
        recieved: DateTime.fromMillisecondsSinceEpoch(a += r.nextInt(1000)),
        temperature: r.nextBool() ? (r.nextDouble() * 50) + 20 : null,
        humidity: r.nextBool() ? (r.nextDouble() * 30) + 20 : null,
        battery: r.nextBool() ? (r.nextInt(1) * 30) + 20 : null,
        location: null,
      );
    });
    list.removeWhere((element) => false);
    return list;
  }

  List<FlSpot>? getTempChart() {
    if (state.records?.isNotEmpty ?? false) {
      var list = state.records!.toList()
        ..removeWhere((element) => element.temperature == null);

      return list
          .map((e) => FlSpot(
              e.timestamp.millisecondsSinceEpoch.toDouble(), e.temperature!))
          .toList();
    }
    return null;
  }

  List<FlSpot>? getHumidityChart() {
    if (state.records?.isNotEmpty ?? false) {
      var list = state.records!.toList()
        ..removeWhere((element) => element.humidity == null);

      return list
          .map((e) => FlSpot(
              e.timestamp.millisecondsSinceEpoch.toDouble(), e.humidity!))
          .toList();
    }
    return null;
  }

  Location? getLastLocation() {
    return state.records?.last.location;
  }

  String? getLastBatteryValue() {
    var battery = state.records?.last.battery;
    if (battery != null) {
      return '${battery.round()} mV';
    } else {
      return null;
    }
  }

  void changeReferenceDate(DateTime time) {
    _referenceDate = time;
  }
}

@freezed
class Record with _$Record {
  factory Record({
    required DateTime timestamp,
    required DateTime recieved,
    double? temperature,
    double? humidity,
    double? battery,
    Location? location,
  }) = _Record;

  factory Record.fromJson(Map<String, dynamic> json) => _$RecordFromJson(json);
}

@freezed
class Location with _$Location {
  factory Location({
    required double longitude,
    required double latitude,
  }) = _Location;

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);
}
