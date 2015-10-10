This is the slide deck and source code for a demonstration of Core Bluetooth that I presented at the [360|iDev min] conference in October of 2015.

# HR BLE Demo
The keynote presentation in PDF format. Includes links to learning resources as well as the Bluetooth SIG standards that I used to create the heart rate monitor demo.
# The 13 Steps
Not to be confused with The 39 Steps this diagram depicts the 13 steps required to acquire a heart rate measurement from a standard Bluetooth LE heart rate monitor. You'll find these steps marked in the example code.
# StressMeter
This is the xcode project that includes all of the demo source code. Since this code is for demonstration is is almost all contained in a single view controller - not the recommended approach for production code. It also doesn't handle all of the various events that would occur in the real world related to disconnects and user activities.

The demonstration code discovers a Bluetooth 4 (LE) peripheral that is advertising the Heart Rate Service. It then connects to the peripheral and begins retrieving the heart rate. You'll need an iOS device that supports Bluetooth 4 and you will need a Bluetooth 4 heart rate sensor. I used the Wahoo Fitness TICKR heart rate monitor but any heart rate monitor that complies with the Bluetooth specification should work. I've also tested the code with a Polar heart rate monitor. The code demonstrates the use of heart rate measurement, in contact indicator, and RR interval but does not do anything with the energy expended characteristic.
