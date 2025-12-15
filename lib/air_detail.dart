import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pm25/air_quality_page.dart';

class AQICardPage extends StatefulWidget {
  final String? selectedAreaTH;
  const AQICardPage({super.key, this.selectedAreaTH});
  @override
  State<AQICardPage> createState() => _AQICardPageState();
}

class _AQICardPageState extends State<AQICardPage> {
  Map<String, dynamic>? station;

  @override
  void initState() {
    super.initState();
    loadAQI(areaTH: widget.selectedAreaTH);
  }

  Future<void> loadAQI({String? areaTH}) async {
    final url = Uri.parse(
      "http://air4thai.pcd.go.th/services/getNewAQI_JSON.php",
    );

    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final stations = data["stations"] ?? [];

      dynamic selected;
      if (stations is List && stations.isNotEmpty) {
        if ((areaTH != null && areaTH.isNotEmpty) ||
            (widget.selectedAreaTH != null &&
                widget.selectedAreaTH!.isNotEmpty)) {
          final target = areaTH ?? widget.selectedAreaTH;
          selected = stations.firstWhere(
            (e) => e["areaTH"]?.toString() == target,
            orElse: () => stations.first,
          );
        } else {
          selected = stations.first;
        }
      }
      setState(() => station = selected);
    }
  }

  Future<void> _openAreaSearch() async {
    final area = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        String query = "";
        bool initialized = false;
        bool loading = true;
        String? error;
        List stationsLocal = [];
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> init() async {
              try {
                final url = Uri.parse(
                  "http://air4thai.pcd.go.th/services/getNewAQI_JSON.php",
                );
                final res = await http.get(url);
                if (res.statusCode == 200) {
                  final data = json.decode(res.body);
                  final s = data["stations"] ?? [];
                  setSheetState(() {
                    stationsLocal = s;
                    loading = false;
                  });
                } else {
                  setSheetState(() {
                    error = "API ${res.statusCode}";
                    loading = false;
                  });
                }
              } catch (e) {
                setSheetState(() {
                  error = "$e";
                  loading = false;
                });
              }
            }

            if (!initialized) {
              initialized = true;
              init();
            }
            final filtered = stationsLocal.where((item) {
              final area = item["areaTH"]?.toString() ?? "";
              return area.toLowerCase().contains(query.trim().toLowerCase());
            }).toList();
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  top: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: "ค้นหาพื้นที่",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (t) => setSheetState(() => query = t),
                    ),
                    const SizedBox(height: 12),
                    if (loading)
                      SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (error != null)
                      SizedBox(height: 200, child: Center(child: Text(error!)))
                    else
                      SizedBox(
                        height: 360,
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final areaTH = item["areaTH"]?.toString() ?? "-";
                            return ListTile(
                              title: Text(areaTH),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(ctx).pop(areaTH),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (area != null && area.isNotEmpty) {
      await loadAQI(areaTH: area);
    }
  }

  Map<String, dynamic> getAQILevel(int aqi) {
    if (aqi <= 50) {
      return {"text": "Good", "color": Colors.green.shade300};
    } else if (aqi <= 100) {
      return {"text": "Moderate", "color": Colors.yellow.shade300};
    } else if (aqi <= 150) {
      return {"text": "Unhealthy", "color": Colors.orange.shade300};
    } else {
      return {"text": "Very Unhealthy", "color": Colors.red.shade300};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (station == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final aqi = int.tryParse(station?["AQILast"]?["AQI"]?["aqi"] ?? "0") ?? 0;
    final pm25 =
        double.tryParse(station?["AQILast"]?["PM25"]?["value"] ?? "0") ?? 0.0;
    final level = getAQILevel(aqi);

    final Color levelColor = level["color"] as Color;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(station?["areaTH"]?.toString() ?? "Rtarf (AQI)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openAreaSearch,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => loadAQI(areaTH: station?["areaTH"]?.toString()),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: station != null
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${station?["areaTH"]} Rtarf(AQI)",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Last updated at ${station?["AQILast"]?["time"]}, ${station?["AQILast"]?["date"]}",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [levelColor, levelColor.withAlpha(217)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.face, size: 50, color: Colors.black54),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$aqi",
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  level["text"],
                                  style: TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("PM2.5"),
                                Text(
                                  "${pm25.toStringAsFixed(1)} µg/m³",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48),
                          backgroundColor: Colors.blueGrey,
                        ),
                        onPressed: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => AirQualityPage(),
                          // ),
                          // );
                        },
                        child: Text("เลือกสถานีอื่นๆ"),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
