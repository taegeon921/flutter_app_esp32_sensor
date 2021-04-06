import 'dart:async';
import 'dart:convert' show utf8;

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_app_esp32_sensor/widgets.dart';
import 'package:flutter_app_esp32_sensor/main.dart';

class SensorPage extends StatefulWidget {
  const SensorPage({Key key, this.device}) : super(key: key);
  final BluetoothDevice device;

  @override
  _SensorPageState createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  bool isReady;
  Stream<List<int>> stream;

  var tempValue = '?';
  var humidityValue = '?';


  @override
  void initState() {
    super.initState();
    isReady = false;
    connectToDevice();
  }

  connectToDevice() async {
    if (widget.device == null) {
      _Pop();
      return;
    }

    new Timer(const Duration(seconds: 15), () {
      if (!isReady) {
        disconnectFromDevice();
        _Pop();
      }
    });

    await widget.device.connect();
    discoverServices();
  }

  disconnectFromDevice() {
    if (widget.device == null) {
      _Pop();
      return;
    }

    widget.device.disconnect();
  }

  discoverServices() async {
    if (widget.device == null) {
      _Pop();
      return;
    }

    List<BluetoothService> services = await widget.device.discoverServices();
    services.forEach((service) {
      if (service.uuid.toString() == SERVICE_UUID) {
        service.characteristics.forEach((characteristic) {
          if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
            characteristic.setNotifyValue(!characteristic.isNotifying);
            stream = characteristic.value;

            setState(() {
              isReady = true;
            });
          }
        });
      }
    });

    if (!isReady) {
      _Pop();
    }
  }

  Future<bool> _onWillPop() {
    return showDialog(
        context: context,
        builder: (context) =>
            new AlertDialog(
              title: Text('확인메세지'),
              content: Text('장치와 연결을 해제하시겠습니까?'),
              actions: <Widget>[
                new FlatButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: new Text('아니오')),
                new FlatButton(
                    onPressed: () {
                      disconnectFromDevice();
                      Navigator.of(context).pop(true);
                    },
                    child: new Text('예')),
              ],
            ) ??
            false);
  }

  _Pop() {
    Navigator.of(context).pop(true);
  }

  String _dataParser(List<int> dataFromDevice) {
    return utf8.decode(dataFromDevice);
  }

  @override
  Widget build(BuildContext context) {


    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title:
          //Image.asset('images/ubigent_logo3.png'),
          Text(widget.device.name),
        ),
        body: Container(
            child: !isReady
                ? Center(
                    child: Text(
                      "로딩중. . .",
                      style: TextStyle(fontSize: 24, color: Colors.blue),
                    ),
                  )
                : Container(
                    child: StreamBuilder<List<int>>(
                      stream: stream,
                      builder: (BuildContext context,
                          AsyncSnapshot<List<int>> snapshot) {
                        if (snapshot.hasError)
                          return Text('Error: ${snapshot.error}');



                        if (snapshot.connectionState ==
                            ConnectionState.active) {
                          //var currentValue = _dataParser(snapshot.data);

                           tempValue = _dataParser(snapshot.data).split("0,")[0];
                           humidityValue = _dataParser(snapshot.data).split(",")[1];

                              print("tempValue: ${tempValue}");
                              print("humidityValue: ${humidityValue}");




                          return Center(
                              child: Row(

                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Card(
                                    child: Container(
                                      width: 150,
                                      height: 200,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Container(
                                            width: 100,
                                            height: 100,
                                            child: Image.asset('images/temperature.png'),
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Text(
                                            "온도",
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Expanded(
                                            child: Container(),
                                          ),
                                          Text(
                                            tempValue+"'C",
                                            style: TextStyle(fontSize: 30),
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Card(
                                    child: Container(
                                      width: 150,
                                      height: 200,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Container(
                                            width: 100,
                                            height: 100,
                                            child: Image.asset('images/humidity.png'),
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Text(
                                            "습도",
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Expanded(
                                            child: Container(),
                                          ),
                                          Text(
                                            humidityValue+"%",
                                            style: TextStyle(fontSize: 30),
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                ],

                              ));
                        } else {
                          return Text('Check the stream');
                        }
                      },
                    ),
                  )),
      ),
    );
  }
}
