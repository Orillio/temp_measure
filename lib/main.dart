import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:temp_sensor/api.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider(
        create: (context) => Api(),
        child: const MyHomePage(
          title: 'Flutter Demo Home Page',
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<Api>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: BlocBuilder<Api, AppState>(
        builder: (context, state) {
          if (state.records == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return BlocListener<Api, AppState>(
            listener: (context, state) {
              var location = bloc.getLastLocation();
              if (location == null) return;
              mapController.move(
                LatLng(
                  location.latitude,
                  location.longitude,
                ),
                9.2,
              );
            },
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    Builder(builder: (context) {
                      var spots = bloc.getTempChart();
                      if (spots == null) {
                        return const Center(
                          child: Text('No graph'),
                        );
                      }
                      return ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 300,
                        ),
                        child: LineChart(
                          LineChartData(
                            minY: -50,
                            maxY: 100,
                            lineBarsData: [
                              LineChartBarData(
                                dotData: FlDotData(show: false),
                                spots: spots,
                              ),
                            ],
                            titlesData: FlTitlesData(
                              topTitles: AxisTitles(
                                axisNameWidget: const Text("Temperature"),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Transform.translate(
                                      offset: const Offset(-10, 50),
                                      child: Transform.rotate(
                                        angle: -pi / 2.5,
                                        child: Text(
                                          DateFormat('dd.MM.yyyy HH:mm:ss')
                                              .format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                  value.toInt(),
                                                ),
                                              )
                                              .toString(),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(
                      height: 200,
                    ),
                    Builder(builder: (context) {
                      var spots = bloc.getHumidityChart();
                      if (spots == null) {
                        return const Center(
                          child: Text('No graph'),
                        );
                      }
                      return ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 300,
                        ),
                        child: LineChart(
                          LineChartData(
                            minY: -50,
                            maxY: 100,
                            lineBarsData: [
                              LineChartBarData(
                                dotData: FlDotData(show: false),
                                spots: spots,
                              ),
                            ],
                            titlesData: FlTitlesData(
                              topTitles: AxisTitles(
                                axisNameWidget: const Text("Humidity"),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Transform.translate(
                                      offset: const Offset(-10, 50),
                                      child: Transform.rotate(
                                        angle: -pi / 2.5,
                                        child: Text(
                                          DateFormat('dd.MM.yyyy HH:mm:ss')
                                              .format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                  value.toInt(),
                                                ),
                                              )
                                              .toString(),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(
                      height: 200,
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  CupertinoButton.filled(
                                    onPressed: () async {
                                      var date = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        lastDate: DateTime.now(),
                                        firstDate: DateTime(2020),
                                      );
                                      if (date != null) {
                                        bloc.changeReferenceDate(date);
                                      }
                                    },
                                    child:
                                        const Text('choose a reference date'),
                                  ),
                                  Text(
                                    'Battery: ${bloc.getLastBatteryValue()?.round() ?? 'No battery info'}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Builder(builder: (context) {
                              var loc = bloc.getLastLocation();
                              if (loc == null) {
                                return const Center(
                                  child: Text('No location'),
                                );
                              }
                              return FlutterMap(
                                mapController: mapController,
                                options: MapOptions(
                                  center: LatLng(
                                    loc.latitude,
                                    loc.longitude,
                                  ),
                                  zoom: 9.2,
                                ),
                                nonRotatedChildren: [
                                  AttributionWidget.defaultWidget(
                                    source: 'OpenStreetMap contributors',
                                    onSourceTapped: null,
                                  ),
                                ],
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.app',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(
                                          loc.latitude,
                                          loc.longitude,
                                        ),
                                        width: 20,
                                        height: 20,
                                        builder: (context) {
                                          return Column(
                                            children: [
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade300,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: Colors.black,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
