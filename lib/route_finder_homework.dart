import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'models/favorite_route.dart';
import 'services/database_helper.dart';

class RouteFinderHomework extends StatefulWidget {
  const RouteFinderHomework({super.key});

  @override
  State<RouteFinderHomework> createState() => _RouteFinderHomeworkState();
}

class _RouteFinderHomeworkState extends State<RouteFinderHomework> {
  final Completer<GoogleMapController> _controller = Completer();

  final TextEditingController startController = TextEditingController();

  final TextEditingController endController = TextEditingController();

  final DatabaseHelper db = DatabaseHelper();

  Set<Marker> markers = {};

  Set<Polyline> polylines = {};

  String selectedMode = "driving";

  static const String apiKey = "AIzaSyDG34Kx3jjsXf2iiFOpAVjXA1xOfERXa_I";

  CameraPosition initialPosition = const CameraPosition(
    target: LatLng(10.7769, 106.7009),
    zoom: 13,
  );

  // ================= GEOCODING =================
  Future<LatLng?> getLatLngFromAddress(String address) async {
    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?"
        "address=${Uri.encodeComponent(address)}"
        "&key=$apiKey";
    final response = await http.get(Uri.parse(url));
    // ignore: avoid_print
    print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["results"].isNotEmpty) {
        final location = data["results"][0]["geometry"]["location"];

        return LatLng(location["lat"], location["lng"]);
      }
    }

    return null;
  }

  // ================= FIND ROUTE =================
  Future<void> findRoute() async {
    try {
      LatLng? start = await getLatLngFromAddress(startController.text);

      LatLng? end = await getLatLngFromAddress(endController.text);

      if (start == null || end == null) {
        ScaffoldMessenger.of(
          // ignore: use_build_context_synchronously
          context,
        ).showSnackBar(const SnackBar(content: Text("Không tìm thấy địa chỉ")));

        return;
      }

      String url =
          "https://maps.googleapis.com/maps/api/directions/json?"
          "origin=${start.latitude},${start.longitude}"
          "&destination=${end.latitude},${end.longitude}"
          "&mode=$selectedMode"
          "&key=$apiKey";

      final response = await http.get(Uri.parse(url));
      // ignore: avoid_print
      print(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["routes"].isNotEmpty) {
          final polyline = data["routes"][0]["overview_polyline"]["points"];

          List<LatLng> points = decodePolyline(polyline);

          setState(() {
            markers.clear();

            polylines.clear();

            markers.add(
              Marker(markerId: const MarkerId("start"), position: start),
            );

            markers.add(Marker(markerId: const MarkerId("end"), position: end));

            polylines.add(
              Polyline(
                polylineId: const PolylineId("route"),
                points: points,
                width: 5,
                color: Colors.blue,
              ),
            );
          });

          final GoogleMapController controller = await _controller.future;

          controller.animateCamera(CameraUpdate.newLatLng(start));
        }
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy đường đi")),
        );
      }
    } catch (e) {
      debugPrint(e.toString());

      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  // ================= SAVE FAVORITE =================
  Future<void> saveFavorite() async {
    final route = FavoriteRoute(
      startAddress: startController.text,

      endAddress: endController.text,

      transportMode: selectedMode,
    );

    await db.insertRoute(route);

    ScaffoldMessenger.of(
      // ignore: use_build_context_synchronously
      context,
    ).showSnackBar(const SnackBar(content: Text("Đã lưu tuyến yêu thích")));
  }

  // ================= POLYLINE =================
  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];

    int index = 0;

    int lat = 0;

    int lng = 0;

    while (index < encoded.length) {
      int b;

      int shift = 0;

      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;

        result |= (b & 0x1f) << shift;

        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      lat += dlat;

      shift = 0;

      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;

        result |= (b & 0x1f) << shift;

        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Google Maps Homework")),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),

            child: Column(
              children: [
                TextField(
                  controller: startController,

                  decoration: const InputDecoration(
                    labelText: "Điểm xuất phát",
                  ),
                ),

                TextField(
                  controller: endController,

                  decoration: const InputDecoration(labelText: "Điểm đích"),
                ),

                const SizedBox(height: 10),

                DropdownButton<String>(
                  value: selectedMode,

                  isExpanded: true,

                  items: const [
                    DropdownMenuItem(value: "driving", child: Text("Ô tô")),

                    DropdownMenuItem(value: "walking", child: Text("Đi bộ")),

                    DropdownMenuItem(value: "bicycling", child: Text("Xe máy")),
                  ],

                  onChanged: (value) {
                    setState(() {
                      selectedMode = value!;
                    });
                  },
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: findRoute,

                  child: const Text("Tìm đường"),
                ),

                ElevatedButton(
                  onPressed: saveFavorite,

                  child: const Text("Lưu yêu thích"),
                ),
              ],
            ),
          ),

          Expanded(
            child: GoogleMap(
              initialCameraPosition: initialPosition,

              markers: markers,

              polylines: polylines,

              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
          ),
        ],
      ),
    );
  }
}
