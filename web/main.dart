// Copyright (c) 2016, Dennis Kaselow. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:convert';

void main() {
  var webSocket = new WebSocket('wss://isowosi.com/ws/c/webstuff');
  webSocket.onOpen.listen((_) async {
    var alpha = 0.0;
    var beta = 0.0;
    var gamma = 0.0;
    var absolute = 0.0;
    BatteryManager batteryManager = await window.navigator.getBattery();
    var battery = batteryManager.level;
    window.onDeviceOrientation.listen((event) {
      alpha = event.alpha;
      beta = event.beta;
      gamma = event.gamma;
      absolute = event.absolute;
    });
    batteryManager.on['levelchange'].listen((_) {
      battery = batteryManager.level;
    });

    new Timer.periodic(new Duration(milliseconds: 100), (_) {
      webSocket.send(JSON.encode({
        'alpha': alpha,
        'beta': beta,
        'gamma': gamma,
        'absolute': absolute,
        'battery': battery,
      }));
    });

    var output = querySelector('#output');
    webSocket.onMessage.listen((event) {
      final divElement = new DivElement();
      divElement.text = event.data;
      output.append(divElement);
      if (output.children.length > 10) {
        output.children.removeAt(0);
      }
    });
  });
}
