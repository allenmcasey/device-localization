#!/usr/bin/python3
import paho.mqtt.client as paho
import json
import socket


# called when a client connects to the server
def on_connect(client, userdata, flags, rc):

    # listen for values from client
    mqttc.subscribe("/values")


def handle_ec2_opt_request(val1, val2, val3, val4):

    range_dat = {
        'req_id': 123,
        'anchors': [0, 1, 2, 3],
        'ranges': [val1, val2, val3, val4],
        'method': METHOD_TOA
    }
    output = json.dumps(range_dat)

    cloud_opt_socket.send(output.encode())
    message = cloud_opt_socket.recv(1024)
    print(message)
    return message


def handle_edge_opt_request(val1, val2, val3, val4):

    range_dat = {
        'req_id': 123,
        'anchors': [0, 1, 2, 3],
        'ranges': [val1, val2, val3, val4],
        'method': METHOD_TOA
    }
    output = json.dumps(range_dat)

    edge_opt_socket.send(output.encode())
    message = edge_opt_socket.recv(1024)
    print(message)
    return message


# forward requests to server
def get_server_response(msg):

    # unpack message
    string_received = str(msg.payload)
    print("CLIENT MESSAGE:" + string_received)
    msg_data = json.loads(string_received)

    # get computation location and type
    compute_location = msg_data["location"].encode("utf-8")
    compute_type = msg_data["type"].encode("utf-8")
    val1 = msg_data["val1"]
    val2 = msg_data["val2"]
    val3 = msg_data["val3"]
    val4 = msg_data["val4"]

    print("\nREQUEST RECEIVED...\n\tLocation: " + compute_location + "\n\tType: " + compute_type)

    # choose appropriate handling method
    if compute_location == "cloud":
        if compute_type == "original":
            server_response = handle_ec2_opt_request(val1, val2, val3, val4)
        else:
            server_response = "not implemented yet"
    else:
        if compute_type == "original":
            server_response = handle_edge_opt_request(val1, val2, val3, val4)
        else:
            server_response = "not implemented yet"

    return server_response


# called when we receive a message from a client
def on_message(client, userdata, msg):

    # forward to server, get response
    response = get_server_response(msg)
    print(response)
    response_data = json.loads(response)

    result_string = str("X: " + str(response_data["value"]["x"]) + " Y: " + str(response_data["value"]["y"]))

    # unpack response, publish back to client
    mqttc.publish("/result", result_string)


METHOD_TOA = 1
METHOD_TDOA = 2

# define server IP addresses
cloud_opt_ip = "52.36.102.253"
cloud_NN_ip = 'WILL HARD-CODE ONCE ESTABLISHED'
edge_opt_ip = '172.23.55.243'
edge_NN_ip = 'WILL HARD-CODE ONCE ESTABLISHED'

# open cloud optimization socket
cloud_opt_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
addr = (cloud_opt_ip, 6789)
cloud_opt_socket.connect(addr)

# open edge optimization socket
edge_opt_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
addr = (edge_opt_ip, 6789)
edge_opt_socket.connect(addr)

# MQTT client definition
mqttc = paho.Client()
mqttc.on_connect = on_connect
mqttc.on_message = on_message

# establish server socket, then loop
mqttc.connect("localhost", 1883)
mqttc.loop_forever()
