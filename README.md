# device-localization

With the proliferation of Personal Mobile Devices (PMDs) over the last several years, the demand for localization applications has increased. These applications typically collect ranging values or timestamps from sensor devices near the user's PMD, and use these values to determine the user's position within a given space. The calculation used to perform localization is typically computationally expensive, and is often offloaded to a secondary device, which introduces further latency. 

The goal of this project is to reduce delay throughout the localization process by reducing two components of the latency:

1. The time required to communicate with the secondary device 
2. The time required for the localization computation 

The first component is explored by using an edge node near the PMD as the secondary computation location in order to reduce transmission delay. This is compared with using a remote EC2 instance in the AWS cloud. The second component is examined by switching from the conventional compute-intensive optimization algorithm for localization to a neural network machine learning model capable of predicting the localization result through regression.

A high level view of the architecture is shown below:


![Architecture of localization project](./assets/localization-architecture.png)


The client application on the mobile device enables the user to select a Computation Location (Edge or Cloud) and a Computation Type (Optimization or Neural Network). The ranging values and the choices for Location and Type are then sent from the client device to the RaspberryPi broker using a JSON message and the MQTT communication protocol. The broker device then unpacks the received JSON and determines what the destination server is based on the Computation Location and Type. Using a list of server IP addresses listed in configuration data, the broker forwards the JSON ranging values to the appropriate edge or cloud server using TCP sockets. The receiving server performs the desired localization computation using the ranging values and sends the positioning results back to the broker on the same socket. Finally, the broker forwards these positioning results back to the client, completing the round trip.
