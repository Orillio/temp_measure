import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api.freezed.dart';

@freezed
class AppState with _$AppState {
  const factory AppState({
    List<Record>? records,
  }) = _AppState;
}

class Api extends Cubit<AppState> {
  final Dio _dio = Dio();
  final Random r = Random();

  DateTime _referenceDate = DateTime(1970);

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
    var a = 1000000;
    var list = List.generate(500, (index) {
      return Record(
        (a += r.nextInt(1000)),
        (a += r.nextInt(1000)),
        r.nextBool() ? (r.nextDouble() * 50) + 20 : null,
        r.nextBool() ? (r.nextDouble() * 30) + 20 : null,
        r.nextBool() ? (r.nextDouble() * 30) + 20 : null,
        r.nextBool()
            ? Location(
                (r.nextDouble() * 60) + 20,
                (r.nextDouble() * 60) + 20,
              )
            : null,
      );
    });
    list.removeWhere((element) => false);
    return list;
  }

  List<FlSpot> getTempChart() {
    if (state.records != null) {
      var list = state.records!.toList()
        ..removeWhere((element) => element.temp == null);

      return list.map((e) => FlSpot(e.ts.toDouble(), e.temp!)).toList();
    }
    return [];
  }

  List<FlSpot> getHumidityChart() {
    if (state.records != null) {
      var list = state.records!.toList()
        ..removeWhere((element) => element.humidity == null);

      return list.map((e) => FlSpot(e.ts.toDouble(), e.humidity!)).toList();
    }
    return [];
  }

  Location getLastLocation() {
    return state.records
            ?.lastWhere((element) => element.location != null)
            .location ??
        Location(0, 0);
  }

  double getLastBatteryValue() {
    return state.records
            ?.lastWhere((element) => element.battery != null)
            .battery ??
        0;
  }

  void changeReferenceDate(DateTime time) {
    _referenceDate = time;
  }
}

class Record {
  final int ts;
  final int received;
  double? temp;
  double? humidity;
  double? battery;
  Location? location;

  Record(this.ts, this.received, this.temp, this.humidity, this.battery,
      this.location);
}

class Location {
  final double longitude;
  final double latitude;

  Location(this.longitude, this.latitude);
}
