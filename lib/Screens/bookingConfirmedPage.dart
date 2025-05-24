import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'landingPage.dart';

class BookingConfirmedPage extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingConfirmedPage({super.key, required this.booking});

  @override
  State<BookingConfirmedPage> createState() => _BookingConfirmedPageState();
}

class _BookingConfirmedPageState extends State<BookingConfirmedPage> {
  final GlobalKey _screenshotKey = GlobalKey();

  String get referenceId {
    if (widget.booking.containsKey('referenceId')) {
      return widget.booking['referenceId'];
    } else {
      var uuid = const Uuid();
      return "REF-${uuid.v4().substring(0, 8)}";
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureAndSaveScreenshot();
    });
  }

  Future<void> _captureAndSaveScreenshot() async {
    try {
      RenderRepaintBoundary boundary = _screenshotKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getExternalStorageDirectory();
      final file = File(
          '${directory!.path}/booking_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      debugPrint('Screenshot saved: ${file.path}');
    } catch (e) {
      debugPrint("Error capturing screenshot: $e");
    }
  }

  Future<void> _shareScreenshot() async {
    try {
      RenderRepaintBoundary boundary = _screenshotKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/screenshot.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)],
          text:
          "I just booked a tee time at ${widget.booking['courseName']}! Reference ID: $referenceId");
    } catch (e) {
      debugPrint("Error sharing screenshot: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseName = widget.booking["courseName"] ?? "Course";
    final date = widget.booking["date"] ?? "N/A";
    final time = widget.booking["time"] ?? "N/A";
    final players = widget.booking["players"] ?? "N/A";
    final total = widget.booking["total"] ?? "N/A";
    final location = widget.booking["Location"] ?? "N/A";
    final addons = widget.booking["addons"] ?? {};

    String coursePlusAddons = courseName;
    if (addons is Map && addons.isNotEmpty) {
      final addonNames = <String>[];
      addons.forEach((addonName, count) {
        if (count != null && count > 0) {
          addonNames.add(addonName);
        }
      });
      if (addonNames.isNotEmpty) {
        coursePlusAddons += " + ${addonNames.join(" + ")}";
      }
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Booking Confirmed",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF252A2E),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF252A2E), Color(0xFF323C44)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                RepaintBoundary(
                  key: _screenshotKey,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.greenAccent,
                            size: 50,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Booking confirmed",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Reference ID: $referenceId",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Booking total  $total THB",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          coursePlusAddons,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          location,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time, color: Colors.black54, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              time,
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.black54, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              date,
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "(Local Time)",
                              style: TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "E-ticket",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: referenceId,
                          width: double.infinity,
                          height: 70,
                          drawText: false,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                IconButton(
                  icon: const Icon(Icons.share, size: 28, color: Colors.white,),
                  onPressed: _shareScreenshot,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LandingPage()),
                            (Route<dynamic> route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(250, 21, 35, 37),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "Back to Home page",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
