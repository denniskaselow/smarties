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
    window.onDeviceOrientation.listen((event) {
      alpha = event.alpha;
      beta = event.beta;
      gamma = event.gamma;
    });
    webSocket.send(JSON.encode({
      'alpha': alpha,
      'beta': beta,
      'gamma': gamma,
    }));
    window.onDeviceMotion.listen((event) {
      var acc = event.acceleration;
      var interval = event.interval;
      var rotationRate = event.rotationRate;
      webSocket.send(JSON.encode({
        'alpha': rotationRate.alpha,
        'beta': rotationRate.beta,
        'gamma': rotationRate.gamma,
        'ax': acc.x,
        'ay': acc.y,
        'az': acc.z,
        'interval': interval,
      }));
    });

    new Timer.periodic(new Duration(milliseconds: 1000), (_) {
      webSocket.send(JSON.encode({
        'alpha': alpha,
        'beta': beta,
        'gamma': gamma,
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
