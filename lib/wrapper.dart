import 'dart:async';
import 'dart:isolate';

import 'package:rxdart/rxdart.dart';

void isolate(SendPort port) {
  var isolateReceivePort = ReceivePort();
  port.send(isolateReceivePort.sendPort);

  isolateReceivePort.listen((message) async {
    print('Received new request');
    SendPort tmpSendPort = message['port'] as SendPort;
    tmpSendPort.send('OK');

    Future(() => port.send('(td_receive)'));
  });

  Future(() => port.send('(td_receive)'));
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
