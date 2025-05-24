import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tee_time/user_state.dart';
import 'package:tee_time/Helper/databaseHelperPage.dart';
import 'package:tee_time/Screens/bookingConfirmedPage.dart';
import 'package:tee_time/Helper/utils.dart';
import 'package:tee_time/Screens/cardInputPage.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> course;
  final int players;
  final String bookingDate;
  final String bookingTime;
  final String selectedHole;
  final String? selectedCorner;
  final bool isPublic;
  final String? notificationId;

  const CheckoutPage({
    super.key,
    required this.course,
    required this.players,
    required this.bookingDate,
    required this.bookingTime,
    required this.selectedHole,
    this.selectedCorner,
    required this.isPublic,
    this.notificationId,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final Map<String, int> addons = {
    "Trolley": 0,
    "Buggy": 0,
    "Caddie": 0,
    "Clubs": 0,
  };

  final Map<String, int> prices = {
    "Trolley": 1000,
    "Buggy": 2000,
    "Caddie": 1500,
    "Clubs": 500,
  };

  String selectedPayment = "Visa";
  String _cardNumber = "";
  bool _isProcessing = false;

  int get baseTotal =>
      (int.tryParse(widget.course["Price"].toString()) ?? 0) * widget.players;

  int get addonsTotal => addons.entries
      .map((e) => e.value * (prices[e.key] ?? 0))
      .fold(0, (a, b) => a + b);

  // Helper method to mask card number.
  String _maskCardNumber(String cardNumber) {
    // Remove any spaces.
    String digits = cardNumber.replaceAll(' ', '');
    if (digits.length <= 4) return cardNumber;
    return "**** **** **** ${digits.substring(digits.length - 4)}";
  }

  void _showCardInputDialog(String method) async {
    // Navigate to CardInputPage and await the returned card number.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardInputPage(method: selectedPayment),
      ),
    );
    if (result != null && result is String) {
      setState(() {
        _cardNumber = result;
      });
    }
  }

  Future<void> _confirmAndPay() async {
    setState(() {
      _isProcessing = true;
    });
    // Validate card input if using a card payment method.
    if (selectedPayment == "Visa" || selectedPayment == "MasterCard") {
      String digits = _cardNumber.replaceAll(' ', '');
      if (digits.length != 16) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid 16-digit card number.")),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }
    }

    final email = normalizeEmail(
      Provider.of<UserState>(context, listen: false).email,
    );

    // Build the booking map.
    final booking = {
      "courseId": widget.course["id"],
      "courseName": widget.course["Name"],
      "userEmail": email,
      "date": widget.bookingDate,
      "time": widget.bookingTime,
      "holes": widget.selectedHole,
      "corner": widget.selectedCorner,
      "players": widget.players,
      "addons": addons,
      "addonsTotal": addonsTotal,
      "courseTotal": baseTotal,
      "total": baseTotal + addonsTotal,
      "paymentMethod": selectedPayment,
      "isPublic": widget.isPublic,
      "referenceId": "BKG-${DateTime.now().millisecondsSinceEpoch}",
    };

    await DatabaseHelper().saveBooking(booking);

    if (widget.isPublic) {
      await DatabaseHelper().saveInvitation(booking);
    }

    if (widget.notificationId != null) {
      await DatabaseHelper()
          .updateNotification(widget.notificationId!, {'status': 'completed'});
    }

    setState(() {
      _isProcessing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment Confirmed: THB ${baseTotal + addonsTotal}")),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmedPage(booking: booking),
        ),
            (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildAddonsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Add-ons",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          ...addons.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${entry.key} (THB ${prices[entry.key]})",
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            if (addons[entry.key]! > 0) {
                              addons[entry.key] = addons[entry.key]! - 1;
                            }
                          });
                        },
                      ),
                      Text("${entry.value}",
                          style: const TextStyle(color: Colors.white, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            addons[entry.key] = addons[entry.key]! + 1;
                          });
                        },
                      ),
                    ],
                  )
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdownCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Price Breakdown",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("Course Price × Players: ${widget.course["Price"]} × ${widget.players} = THB $baseTotal",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            ...addons.entries.where((entry) => entry.value > 0).map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                    "${entry.key}: ${entry.value} × ${prices[entry.key]} = THB ${entry.value * prices[entry.key]!}",
                    style: const TextStyle(fontSize: 16)),
              );
            }).toList(),
            const Divider(color: Colors.black45, height: 24),
            Text("Total: THB ${baseTotal + addonsTotal}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    // Dynamic label for Visa: if _cardNumber is provided, mask it.
    List<Map<String, String>> paymentMethods = [
      {
        'label': selectedPayment == "Visa" && _cardNumber.isNotEmpty
            ? "Visa ${_maskCardNumber(_cardNumber)}"
            : "Visa **** **** **** ****",
        'method': 'Visa',
        'icon': 'assets/img/visa.png',
      },
      {
        'label': "MasterCard **** **** **** ****",
        'method': 'MasterCard',
        'icon': 'assets/img/mastercard.png',
      },
    ];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Payment Method",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Column(
            children: paymentMethods.map((card) {
              return GestureDetector(
                onTap: () => setState(() => selectedPayment = card['method']!),
                onLongPress: () {
                  _showCardInputDialog(selectedPayment);
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[800],
                    border: Border.all(
                      color: selectedPayment == card['method'] ? Colors.amber : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        card['icon']!,
                        height: 24,
                        width: 32,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(card['label']!, style: const TextStyle(color: Colors.white, fontSize: 16))),
                      if (selectedPayment == card['method'])
                        const Icon(Icons.check_circle, color: Colors.amber),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAddonsSection(),
                    _buildPriceBreakdownCard(),
                    _buildPaymentMethodSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              width: double.infinity,
              child: _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _confirmAndPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(250, 21, 35, 37),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text("Confirm & Pay",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
