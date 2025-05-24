import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tee_time/Helper/databaseHelperPage.dart';
import '../user_state.dart';
import 'package:tee_time/Helper/utils.dart';

class OpenInvitationsPage extends StatelessWidget {
  final Map<String, dynamic> course;
  const OpenInvitationsPage({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final String courseId = course['id'].toString();
    debugPrint("Querying invitations for courseId: $courseId");
    return Scaffold(
      appBar: AppBar(
        title: Text("Open Invitations for ${course["Name"]}"),
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper().getOpenInvitations(courseId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint("Error in openInvitations: ${snapshot.error}");
              return const Center(
                  child: Text("Something went wrong",
                      style: TextStyle(color: Colors.white, fontSize: 16)));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final invitations = snapshot.data!;
            if (invitations.isEmpty) {
              debugPrint("No invitations found for courseId: $courseId");
              return const Center(
                  child: Text("No open invitations available.",
                      style: TextStyle(color: Colors.white, fontSize: 16)));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: invitations.length,
              separatorBuilder: (context, index) =>
              const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final invitation = invitations[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey[200]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.black54),
                      ),
                      title: Text(
                        "Invitation by ${invitation['userEmail']}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Date: ${invitation['date']} | Time: ${invitation['time']}\nHoles: ${invitation['holes']}"
                              "${invitation['corner'] != null ? ' | Corner: ${invitation['corner']}' : ''}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF252A2E),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final currentUser = normalizeEmail(
                            Provider.of<UserState>(context, listen: false).email,
                          );
                          final invitationCreator = normalizeEmail(
                            invitation['userEmail'].toString(),
                          );
                          debugPrint("Sending join request from $currentUser to $invitationCreator");
                          final requestNotif = {
                            'type': 'invitation_request',
                            'title': 'New Invitation Request',
                            'message': '$currentUser wants to join your invitation.',
                            'fromUser': currentUser,
                            'toUser': invitationCreator,
                            'invitationId': invitation['id'],
                            'courseId': courseId,
                            'courseName': course["Name"],
                            'coursePrice': course["Price"],
                            'date': invitation['date'],
                            'time': invitation['time'],
                            'holes': invitation['holes'],
                            'corner': invitation['corner'],
                            'status': 'pending',
                            'timestamp': DateTime.now().toIso8601String(),
                          };
                          bool sent = await DatabaseHelper().sendNotification(requestNotif);
                          if (sent) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Request sent")),
                            );
                          }
                        },
                        child: const Text("Join",
                            style: TextStyle(fontSize: 14, color: Colors.white)),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
