import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double latitude = -7.234330;
  double longitude = -35.929841;
  List<Place> places =  List();

  String geofenceState = '';
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    var initializationSettingsAndroid =
    new AndroidInitializationSettings('ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings(
    );
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);

    ////
    // 1.  Listen to events (See docs for all 12 available events).
    //

    Place place = Place(-7.234330, -35.929841, "Casa");
    Place place2 = Place(-7.235537, -35.931720, "Condominio colinas do sol");
    Place place3 = Place(-7.238125, -35.930594, "HELP");

    places.add(place);
    places.add(place2);
    places.add(place3);

    // Fired whenever a location is recorded
    bg.BackgroundGeolocation.onLocation((bg.Location location) {

      setState(() {
        latitude = location.coords.latitude;
        longitude = location.coords.longitude;
      });
      print('[location] - $location');

    });

    // Fired whenever the plugin changes motion-state (stationary->moving and vice-versa)
    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      print('[motionchange] - $location');
    });

    // Fired whenever the state of location-services changes.  Always fired at boot
    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      print('[providerchange] - $event');
    });

    bg.BackgroundGeolocation.onGeofence((bg.GeofenceEvent event) {
      print('[geofence] ${event.identifier}, ${event.action}');
      _showNotification(event.action, event.identifier);
      setState(() {
        geofenceState = event.identifier.toString();
      });
    });

    ////
    // 2.  Configure the plugin
    //
    bg.BackgroundGeolocation.ready(bg.Config(
            desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
            distanceFilter: 10.0,
            stopOnTerminate: false,
            startOnBoot: true,
            debug: true,
            logLevel: bg.Config.LOG_LEVEL_VERBOSE,
            reset: true))
        .then((bg.State state) {
      if (!state.enabled) {
        ////
        // 3.  Start the plugin.
        //
        bg.BackgroundGeolocation.start();
      }
      _addGeofences();
    });
  }

  Future onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }

  }

  Future _showNotification(String title, String msg) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'geofence', 'geofence', 'Geofence notification',
        importance: Importance.Max, priority: Priority.High);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, title, msg, platformChannelSpecifics,
        payload: 'item id 2');

    print('Notification shown');


  }

  void _addGeofences() {
    places.forEach( (p) => _addGeofence(p) );
  }

  void _addGeofence(Place place) {

    bg.BackgroundGeolocation.addGeofence(bg.Geofence(
    identifier: place.name,
    radius: 100,
    latitude: place.latitude,
    longitude: place.longitude,
    notifyOnEntry: true,
    notifyOnExit: true,
    extras: {"route_id": 1234})).then((bool success) {
    print('[addGeofence] success');
    geofenceState = "success";
    }).catchError((dynamic error) {
    print('[addGeofence] FAILURE: $error');
    geofenceState = "FAILURE";
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Flutter Geofencing Example'),
          ),
          body: Container(
              padding: const EdgeInsets.all(20.0),
              child: Column (
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Center(child: Text("Geofence state: " + geofenceState)),
                    Center(child: Text("Location: lon" + latitude.toString() + ", lat: " + longitude.toString()))
                  ],

              ) )),
    );
  }
}

class Place {

  double latitude;
  double longitude;
  String name;
  Place(this.latitude, this.longitude, this.name);
}