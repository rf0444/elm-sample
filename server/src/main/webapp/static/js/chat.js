(function() { "use strict";
	var app = Elm.embed(Elm.Main.Chat, document.getElementById("main"), {
		mqttMessageArrived: "",
		mqttConnected: []
	});
	var mqttClient = null;
	app.ports.mqttConnect.subscribe(function(mqttInfo) {
		if (mqttInfo == null) {
			return;
		}
		var client = new Paho.MQTT.Client(mqttInfo.host, mqttInfo.port_, mqttInfo.clientId);
		client.onMessageArrived = function(message) {
			app.ports.mqttMessageArrived.send(message.payloadString);
		};
		client.connect({
			timeout: 3,
			userName: mqttInfo.username,
			password: mqttInfo.password,
			onSuccess: function() {
				client.subscribe("/chat", {
					qos: 0,
                    onSuccess: function() {
						mqttClient = client;
						app.ports.mqttConnected.send([]);
					}
				});
			}
		});
	});
	app.ports.mqttSend.subscribe(function(s) {
		if (mqttClient == null || s == "") {
			return;
		}
		var message = new Paho.MQTT.Message(s);
		message.destinationName = '/chat';
		message.qos = 0;
		message.retained = false;
		mqttClient.send(message);
	});
	window.app = app;
})();
