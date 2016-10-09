// Copyright (c) 2016, Dennis Kaselow. All rights reserved. Use of this source code

// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:convert';

void main() {
  var webSocket = new WebSocket('wss://isowosi.com/ws/c/webstuff');
  webSocket.onOpen.listen((_) async {
    webSocket.onMessage.listen((event) {
      var data = JSON.decode(event.data);
      debug(event.data);

      try {
        if (data is Map &&
            data.containsKey('content') &&
            data['content'] != 'removeClient') {
          var payload = JSON.decode(data['content']);
          if (payload is Map && payload.containsKey('type')) {
            switch (payload['type']) {
              case 'notification':
                displayNotification(payload);
                break;
              case 'devicedata':
                deviceData(webSocket);
                break;
              case 'changeColor':
                changeColor(payload);
                break;
              case 'chat':
                querySelector('#chat').style.display = 'block';
                break;
            }
          }
        }
      } catch (e, stacktrace) {
        debug(e);
        debug(stacktrace);
      }
    });
  });

  var bcWebSocket = new WebSocket('wss://isowosi.com/ws/bc/webstuff');
  bcWebSocket.onOpen.listen((_) {
    InputElement chat = querySelector('#chat');
    chat.onKeyPress.listen((event) {
      if (event.keyCode == KeyCode.ENTER) {
        final divElement = new DivElement();
        divElement.appendText('Ich: ${chat.value}');
        bcWebSocket.send(JSON.encode({'type': 'chat', 'content': chat.value}));
        chat.value = '';
        querySelector('#output').append(divElement);
      }
    });
    bcWebSocket.onMessage.listen((event) {
      Map data = JSON.decode(event.data);
      try {
        if (data.containsKey('content') && data['content'] != 'removeClient') {
          Map payload = JSON.decode(data['content']);
          if (payload['type'] == 'chat') {
            final divElement = new DivElement();
            divElement.appendText('${data['id']}: ${payload['content']}');
            querySelector('#output').append(divElement);
          }
        }
      } catch (_) {}
    });
  });
}

void deviceData(WebSocket webSocket) {
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
}

void debug(rawText) {
  final output = querySelector('div#debug');
  final preElement = new PreElement();
  preElement.text = rawText;
  output.append(preElement);
  if (output.children.length > 10) {
    output.children.removeAt(0);
  }
}

void displayNotification(Map<String, String> payload) {
  if (Notification.supported) {
    Notification.requestPermission().then((_) {
      new Notification('Möglichkeiten des Web',
          body: payload['content'], icon: 'MdW.png');
    });
  } else {
    debug('Notifications werden von deinem Gerät nicht unterstützt :(');
  }
}

void changeColor(Map payload) {
  var hsl = JSON.decode(payload['content']);
  querySelector('body').style.backgroundColor =
      'hsl(${hsl['h']}, ${hsl['s']}%, ${hsl['l']}%)';
}
