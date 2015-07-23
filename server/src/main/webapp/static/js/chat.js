(function() { "use strict";
	var app = Elm.embed(Elm.Chat.Main, document.getElementById("main"), {
		toElm: null
	});
	var mqttClient = null;
	var connect = function (data) {
		var mqttInfo = data.info;
		var client = new Paho.MQTT.Client(mqttInfo.host, mqttInfo.port, mqttInfo.clientId);
		client.onMessageArrived = function(message) {
			app.ports.toElm.send({ type: "messageArrived", message: message.payloadString });
		};
		client.connect({
			timeout: 3,
			userName: mqttInfo.username,
			password: mqttInfo.password,
			onSuccess: function() {
				client.subscribe(data.destination, {
					qos: 0,
					onSuccess: function() {
						mqttClient = client;
						app.ports.toElm.send({ type: "connected" });
					}
				});
			}
		});
	};
	var send = function(data) {
		if (mqttClient == null) {
			return;
		}
		var message = new Paho.MQTT.Message(data.message);
		message.destinationName = data.destination;
		message.qos = 0;
		message.retained = false;
		mqttClient.send(message);
	};
	app.ports.fromElm.subscribe(function(data) {
		if (data == null) {
			return;
		}
		switch (data.type) {
		case "connect":
			connect(data.data);
			break;
		case "send":
			send(data.data);
			break;
		default:
			break;
		}
	});
	window.app = app;
})();
