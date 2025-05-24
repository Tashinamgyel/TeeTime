import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Helper/databaseHelperPage.dart';
import 'checkOutpage.dart';
import 'openInvitationPage.dart';


class BookingPage extends StatefulWidget {
  final Map<String, dynamic> course;
  const BookingPage({super.key, required this.course});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _timeController = TextEditingController();

  String _selectedDateText = "";

  String selectedHole = "18H";
  String selectedCorner = "First Corner";
  int players = 1;
  bool isPublic = false;
  bool _isProcessing = false;


  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() {
            _selectedDateText =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDateText.isEmpty ? "Choose booking date" : _selectedDateText,
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            const Icon(Icons.calendar_today, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) {
          int hour = picked.hour;
          int minute = picked.minute;
          int roundedMinute;

          if (minute < 15) {
            roundedMinute = 0;
          } else if (minute < 45) {
            roundedMinute = 30;
          } else {
            roundedMinute = 0;
            hour = (hour + 1) % 24;
          }
          final adjustedTime = TimeOfDay(hour: hour, minute: roundedMinute);
          setState(() {
            _timeController.text = adjustedTime.format(context);
          });

          if (_selectedDateText.isNotEmpty) {
            await _checkBookingAvailability();
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _timeController.text.isEmpty ? "Choose time" : _timeController.text,
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            const Icon(Icons.access_time, color: Colors.black54),
          ],
        ),
      ),
    );
  }


  Future<void> _checkBookingAvailability() async {
    if (_selectedDateText.isEmpty || _timeController.text.isEmpty) return;
    final String courseId = widget.course["id"].toString();
    final String bookingDate = _selectedDateText;
    final String bookingTime = _timeController.text;
    final String sanitizedTime = bookingTime.replaceAll(":", "-").replaceAll(" ", "");
    final String bookingId = "BKG_${courseId}_${bookingDate}_$sanitizedTime";
    final url = Uri.parse('${Config.BOOKING_DB_URL}bookings/$bookingId.json');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200 && response.body != "null") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("This slot is already booked. Please choose a different time or slot.")));
        setState(() {
          _timeController.clear();
        });
      }
    } catch (e) {
      // Optionally handle errors here.
    }
  }

  Widget _buildHoleSelection() {
    return Row(
      children: [
        ChoiceChip(
          label: const Text("9 Holes"),
          selected: selectedHole == "9H",
          onSelected: (bool selected) {
            setState(() {
              selectedHole = "9H";
            });
          },
          selectedColor: Colors.amberAccent,
          backgroundColor: Colors.grey[800],
          labelStyle: TextStyle(color: selectedHole == "9H" ? Colors.black : Colors.white),
        ),
        const SizedBox(width: 12),
        ChoiceChip(
          label: const Text("18 Holes"),
          selected: selectedHole == "18H",
          onSelected: (bool selected) {
            setState(() {
              selectedHole = "18H";
            });
          },
          selectedColor: Colors.amberAccent,
          backgroundColor: Colors.grey[800],
          labelStyle: TextStyle(color: selectedHole == "18H" ? Colors.black : Colors.white),
        ),
      ],
    );
  }

  Widget _buildPlayerCount() {
    final rawPrice = widget.course["Price"];
    final num price = num.tryParse(rawPrice.toString()) ?? 0;
    final total = price * players;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: players > 1 ? () => setState(() => players--) : null,
            icon: const Icon(Icons.remove_circle, color: Colors.white),
          ),
          Text("$players", style: const TextStyle(fontSize: 18, color: Colors.white)),
          IconButton(
            onPressed: players < 5 ? () => setState(() => players++) : null,
            icon: const Icon(Icons.add_circle, color: Colors.white),
          ),
          const Spacer(),
          Text("Total: ${total.toStringAsFixed(0)} THB",
              style: const TextStyle(
                  color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPublicToggle() {
    return Row(
      children: [
        const Text("Make this booking public",
            style: TextStyle(color: Colors.white, fontSize: 16)),
        const Spacer(),
        Switch(
          value: isPublic,
          onChanged: (val) => setState(() => isPublic = val),
          activeColor: Colors.amberAccent,
        ),
      ],
    );
  }

  Widget _buildTopButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Map placeholder - future feature")),
              );
            },
            icon: const Icon(Icons.map, size: 20, color: Colors.white),
            label: const Text("Map", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OpenInvitationsPage(course: widget.course),
                ),
              );
            },
            icon: const Icon(Icons.people_alt_rounded, size: 20, color: Colors.white),
            label: const Text("Open Invitations", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final courseName = course["Name"] ?? "Course";
    return Scaffold(
      appBar: AppBar(
        title: Text("Book $courseName",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF252A2E),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF252A2E), Color(0xFF323C44)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/img/${course["id"]}.jpg',
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTopButtons(),
                      const SizedBox(height: 20),
                      Text(courseName,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text("${course["Price"]} THB",
                          style: const TextStyle(fontSize: 18, color: Colors.greenAccent)),
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Schedule",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 12),
                            _buildDatePicker(),
                            const SizedBox(height: 12),
                            _buildTimePicker(),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Playing Details",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 12),
                            _buildHoleSelection(),
                            if (selectedHole == "9H") ...[
                              const SizedBox(height: 12),
                              const Text("Select Corner", style: TextStyle(color: Colors.white, fontSize: 16)),
                              Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text("First Corner"),
                                    selected: selectedCorner == "First Corner",
                                    onSelected: (bool selected) {
                                      setState(() {
                                        selectedCorner = "First Corner";
                                      });
                                    },
                                    selectedColor: Colors.amberAccent,
                                    backgroundColor: Colors.grey[800],
                                    labelStyle: TextStyle(
                                        color: selectedCorner == "First Corner" ? Colors.black : Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  ChoiceChip(
                                    label: const Text("Second Corner"),
                                    selected: selectedCorner == "Second Corner",
                                    onSelected: (bool selected) {
                                      setState(() {
                                        selectedCorner = "Second Corner";
                                      });
                                    },
                                    selectedColor: Colors.amberAccent,
                                    backgroundColor: Colors.grey[800],
                                    labelStyle: TextStyle(
                                        color: selectedCorner == "Second Corner" ? Colors.black : Colors.white),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            _buildPlayerCount(),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildPublicToggle(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: const Color(0xFF323C44),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate() ||
                        _selectedDateText.isEmpty ||
                        _timeController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill all fields")),
                      );
                      return;
                    }
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutPage(
                          course: widget.course,
                          players: players,
                          bookingDate: _selectedDateText,
                          bookingTime: _timeController.text,
                          selectedHole: selectedHole,
                          selectedCorner: selectedHole == "9H" ? selectedCorner : null,
                          isPublic: isPublic,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(250, 21, 35, 37),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text("Next",
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

