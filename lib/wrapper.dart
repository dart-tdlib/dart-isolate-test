import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _receiveEvent(SendPort port) async {
  final event = await Future(
      () => Random().nextInt(10000) == 2 ? '*tdlib request*' : null);
  if (event != null) {
    port.send(event);
  }
  Future(() => _receiveEvent(port));
}

void isolate(SendPort port) {
  var isolateReceivePort = ReceivePort();
  port.send(isolateReceivePort.sendPort);

  isolateReceivePort.listen((message) async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString('test', DateTime.now().toString());
    print('Received new request');
    SendPort tmpSendPort = message['port'] as SendPort;
    tmpSendPort.send('OK');
  });

  //_receiveEvent(port);
}

class Wrapper {
  Isolate _isolate;
  SendPort _sendPort;
  ReceivePort receivePort;
  BehaviorSubject subject = BehaviorSubject();

  Future<void> initIsolate() async {
    receivePort = ReceivePort();

    _isolate = await Isolate.spawn(isolate, receivePort.sendPort);

    receivePort.listen((message) => subject.add(message));
    _sendPort = (await subject.first) as SendPort;
  }

  Future<dynamic> sendRequest() async {
    var tmpReceivePort = ReceivePort();
    _sendPort.send({'port': tmpReceivePort.sendPort});
  }

  Future<void> dispose() async => _isolate.kill();
}
